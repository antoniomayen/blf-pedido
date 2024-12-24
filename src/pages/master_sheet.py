import streamlit as st
import pandas as pd
from config.database import DatabaseConnection
import io

def get_master_data():
    with DatabaseConnection() as conn:
        query = """
        SELECT 
            master_code, product_no, color, group_code, 
            product_name, blf_code, price_without_tax,
            price_with_tax, cost_price
        FROM master_products
        """
        return pd.read_sql(query, conn)

def validate_master_code(product_no, color):
    if not product_no or not color:
        raise ValueError("Product No and Color are required fields")
    return f"{product_no}_{color}"

def validate_data(df):
    errors = []
    
    if df['product_no'].isnull().any():
        errors.append("Product No cannot be empty")
    if df['color'].isnull().any():
        errors.append("Color cannot be empty")
        
    if not df['product_no'].str.match(r'^[A-Za-z0-9-]+$').all():
        errors.append("Product No can only contain letters, numbers, and hyphens")
    if not df['color'].str.match(r'^[A-Za-z0-9-]+$').all():
        errors.append("Color can only contain letters, numbers, and hyphens")
        
    duplicate_combinations = df.duplicated(subset=['product_no', 'color'], keep=False)
    if duplicate_combinations.any():
        duplicates = df[duplicate_combinations][['product_no', 'color']]
        errors.append(f"Duplicate product_no and color combinations found: {duplicates.to_dict('records')}")
    
    return errors

def check_existing_records(df, conn):
    cursor = conn.cursor()
    existing_records = []
    new_records = []
    
    for _, row in df.iterrows():
        master_code = validate_master_code(row['product_no'], row['color'])
        cursor.execute("SELECT master_code FROM master_products WHERE master_code = %s", (master_code,))
        if cursor.fetchone():
            existing_records.append({
                'row': _ + 1,
                'master_code': master_code,
                'product_no': row['product_no'],
                'color': row['color']
            })
        else:
            new_records.append({
                'row': _ + 1,
                'master_code': master_code,
                'product_no': row['product_no'],
                'color': row['color']
            })
    
    return existing_records, new_records

def save_to_database(df):
    errors = validate_data(df)
    if errors:
        raise ValueError("\n".join(errors))
        
    with DatabaseConnection() as conn:
        existing_records, new_records = check_existing_records(df, conn)
        
        if existing_records:
            existing_msg = "\n".join([
                f"Row {rec['row']}: {rec['master_code']} ({rec['product_no']} - {rec['color']})"
                for rec in existing_records
            ])
            st.warning(f"Found {len(existing_records)} existing records that will be skipped:\n{existing_msg}")
        
        if not new_records:
            st.info("No new records to import.")
            return 0
            
        cursor = conn.cursor()
        imported_count = 0
        
        for record in new_records:
            try:
                row = df.iloc[record['row'] - 1]
                query = """
                INSERT INTO master_products 
                    (master_code, product_no, color, group_code, product_name)
                VALUES (%s, %s, %s, %s, %s)
                """
                cursor.execute(query, (
                    record['master_code'],
                    row['product_no'],
                    row['color'],
                    row.get('group_code', None),
                    row.get('product_name', None)
                ))
                imported_count += 1
                
            except Exception as e:
                conn.rollback()
                raise Exception(f"Error in row {record['row']}: {str(e)}")
        
        conn.commit()
        return imported_count

def handle_file_upload():
    uploaded_file = st.file_uploader("Choose a CSV file", type='csv')
    if uploaded_file is not None:
        try:
            df = pd.read_csv(uploaded_file)
            required_columns = ['product_no', 'color']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                st.error(f"Missing required columns: {', '.join(missing_columns)}")
                return None
                
            # Limpiar datos
            df = df.replace({pd.NA: None})
            for col in df.columns:
                if df[col].dtype == 'object':
                    df[col] = df[col].str.strip()
            
            errors = validate_data(df)
            if errors:
                st.error("\n".join(errors))
                return None
                
            df['master_code'] = df.apply(lambda x: validate_master_code(x['product_no'], x['color']), axis=1)
            return df
            
        except Exception as e:
            st.error(f"Error processing file: {str(e)}")
            return None
    return None

def export_to_excel(df):
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
        df.to_excel(writer, sheet_name='Master Sheet', index=False)
    return output.getvalue()

def render_master_sheet():
    st.title("Master Sheet")
    
    tab1, tab2 = st.tabs(["View/Edit Data", "Import Data"])
    
    with tab1:
        df = get_master_data()
        st.write(f"Total records: {len(df)}")
        
        # Agregar campo de búsqueda
        search = st.text_input("Search in any field:", "")
        
        # Filtrar el DataFrame basado en la búsqueda
        if search:
            mask = df.astype(str).apply(lambda x: x.str.contains(search, case=False)).any(axis=1)
            filtered_df = df[mask]
        else:
            filtered_df = df
            
        # Agregar opciones de ordenamiento
        sort_col = st.selectbox("Sort by:", df.columns.tolist())
        sort_order = st.radio("Order:", ["Ascending", "Descending"], horizontal=True)
        
        if sort_order == "Ascending":
            filtered_df = filtered_df.sort_values(by=sort_col)
        else:
            filtered_df = filtered_df.sort_values(by=sort_col, ascending=False)
        
        # Paginación
        rows_per_page = st.selectbox("Rows per page:", [10, 25, 50, 100])
        page = st.number_input("Page", min_value=1, value=1)
        total_pages = len(filtered_df) // rows_per_page + (1 if len(filtered_df) % rows_per_page > 0 else 0)
        
        start_idx = (page - 1) * rows_per_page
        end_idx = start_idx + rows_per_page
        
        # Mostrar información de paginación
        st.write(f"Page {page} of {total_pages}")
        
        # Mostrar la tabla paginada
        st.dataframe(
            filtered_df.iloc[start_idx:end_idx],
            use_container_width=True,
            hide_index=True
        )
        
        col1, col2 = st.columns(2)
        with col1:
            if st.button("Save Changes"):
                try:
                    save_to_database(filtered_df)
                    st.success("Changes saved successfully!")
                except Exception as e:
                    st.error(f"Error saving changes: {str(e)}")
        
        with col2:
            if st.button("Export to Excel"):
                excel_data = export_to_excel(filtered_df)
                st.download_button(
                    "Download Excel file",
                    excel_data,
                    "master_sheet.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
    
    with tab2:
        uploaded_df = handle_file_upload()
        if uploaded_df is not None:
            col1, col2 = st.columns([1, 2])
            with col1:
                st.info(f"CSV loaded successfully! \nTotal rows: {len(uploaded_df)}")
            
            if st.button("Import Data", type="primary"):
                try:
                    with st.spinner("Checking records..."):
                        imported_count = save_to_database(uploaded_df)
                        if imported_count > 0:
                            st.success(f"✅ Successfully imported {imported_count} new records!")
                            st.balloons()
                        st.experimental_rerun()
                except Exception as e:
                    st.error(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    render_master_sheet()