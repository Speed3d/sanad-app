using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Linq;
using System.Windows.Forms;
using DevExpress.XtraEditors;

namespace Sales_Managment
{
    public partial class Frm_AddMoney_S_Contractors : DevExpress.XtraEditors.XtraForm
    {
        public Frm_AddMoney_S_Contractors()
        {
            InitializeComponent();
        }

        DataTable tbl = new DataTable();
        Database db = new Database();

        private void onLoadScreen()
        {
            fillStock();
            tbl.Clear();
            tbl = db.readData("select * from Stock_Contractors where Stock_ID=" + cbxStock.SelectedValue + "", "");
            if (tbl.Rows.Count <= 0)
            {
                db.exceuteData("insert into Stock_Contractors values (" + cbxStock.SelectedValue + " , 0)", "");
                tbl = db.readData("select * from Stock_Contractors where Stock_ID=" + cbxStock.SelectedValue + "", "");
            }
            if (Convert.ToDecimal(tbl.Rows[0][1]) <= 0)
            {
                lblMoney.Text = "0";
            }
            else if (Convert.ToDecimal(tbl.Rows[0][1]) >= 1)
            {
                lblMoney.Text = Convert.ToDecimal(tbl.Rows[0][1]) + "";
            }
            NudPrice.Value = 1;
        }

        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data_Contractors", "");
            cbxStock.DisplayMember = "Stock_Contractors_Name";
            cbxStock.ValueMember = "Stock_Contractors_ID";
        }

        private void Frm_AddMoney_S_Contractors_Load(object sender, EventArgs e)
        {
            try
            {
                onLoadScreen();
            }
            catch (Exception) { }
        }

        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (cbxStock.Items.Count >= 1)
            {
                if (NudPrice.Value <= 0) { MessageBox.Show("لابد ان يكون مبلغ الايداع اكبر من صفر", "تاكيد"); return; }
                db.exceuteData("update Stock_Contractors set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "تم الايداع بنجاح");
                onLoadScreen();
            }
        }

        private void cbxStock_SelectionChangeCommitted(object sender, EventArgs e)
        {
            try
            {
                tbl.Clear();
                tbl = db.readData("select * from Stock_Contractors where Stock_ID=" + cbxStock.SelectedValue + "", "");
                if (tbl.Rows.Count <= 0)
                {
                    db.exceuteData("insert into Stock_Contractors values (" + cbxStock.SelectedValue + " , 0)", "");
                    tbl = db.readData("select * from Stock_Contractors where Stock_ID=" + cbxStock.SelectedValue + "", "");
                }
                if (Convert.ToDecimal(tbl.Rows[0][1]) <= 0)
                {
                    lblMoney.Text = "0";
                }
                else if (Convert.ToDecimal(tbl.Rows[0][1]) >= 1)
                {
                    lblMoney.Text = Convert.ToDecimal(tbl.Rows[0][1]) + "";
                }
            }
            catch (Exception) { }
        }

    }
}