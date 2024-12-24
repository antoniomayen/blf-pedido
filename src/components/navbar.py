import streamlit as st

def render_navbar():
    st.markdown(
        """
        <style>
        .navbar {
            padding: 1rem;
            background-color: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
            margin-bottom: 2rem;
        }
        .nav-item {
            margin-right: 1rem;
            text-decoration: none;
            color: #1a1a1a;
        }
        </style>
        """, 
        unsafe_allow_html=True
    )
    
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        if st.button("Master Sheet"):
            st.session_state.page = "master"
    with col2:
        if st.button("Sales Contract"):
            st.session_state.page = "sc"
    with col3:
        if st.button("Inventory"):
            st.session_state.page = "inventory"
    with col4:
        if st.button("Reports"):
            st.session_state.page = "reports"
