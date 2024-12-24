import streamlit as st
from pages.master_sheet import render_master_sheet

st.set_page_config(
    page_title="BLF Master",
    page_icon="📊",
    layout="wide"
)

render_master_sheet()