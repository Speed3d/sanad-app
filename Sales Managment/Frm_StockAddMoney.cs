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
    public partial class Frm_StockAddMoney : DevExpress.XtraEditors.XtraForm
    {
        public Frm_StockAddMoney()
        {
            InitializeComponent();
        }
        DataTable tbl = new DataTable();
        Database db = new Database();

        int row;
        private void Show()
        {
            tbl.Clear();
            tbl = db.readData("select * from Stock_Insert", "");

            if (tbl.Rows.Count <= 0)
            {
                MessageBox.Show("لا يوجد بيانات فى هذه الشاشه");
            }
            else
            {
                try
                {
                    //txtID.Text = tbl.Rows[row][0].ToString();
                    cbxStock.SelectedValue = tbl.Rows[row][1].ToString();
                    NudPrice.Value = Convert.ToDecimal(tbl.Rows[row][2]);
                    this.Text = tbl.Rows[row][3].ToString();
                    DateTime dt = DateTime.ParseExact(this.Text, "dd/MM/yyyy", null);
                    DtpDate.Value = dt;
                    txtName.Text = tbl.Rows[row][4].ToString();
                    txtFrom.Text = tbl.Rows[row][5].ToString();
                    txtreason.Text = tbl.Rows[row][6].ToString();
                    
                }
                catch (Exception) { }
            }

        }

        private void onLoadScreen()
        {
            fillStock();
            tbl.Clear();
            tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            if (tbl.Rows.Count <= 0)
            {
                db.exceuteData("insert into Stock values (" + cbxStock.SelectedValue + " , 0)", "");
                tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
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
            txtName.Clear();
            txtreason.Clear();

        }
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }
        private void Frm_StockAddMoney_Load(object sender, EventArgs e)
        { try
            {
                onLoadScreen();
                btnEdit.Enabled = false;
            } catch (Exception) { }
        }

        private void cbxStock_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void cbxStock_SelectionChangeCommitted(object sender, EventArgs e)
        {
            try
            {
                tbl.Clear();
                tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
                if (tbl.Rows.Count <= 0)
                {
                    db.exceuteData("insert into Stock values (" + cbxStock.SelectedValue + " , 0)", "");
                    tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
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

        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (cbxStock.Items.Count >= 1)
            {
                string d = DtpDate.Value.ToString("dd/MM/yyyy");
                if (txtName.Text == "") { MessageBox.Show("من فضلك ادخل اسم المودع", "تاكيد"); return; }
                if (NudPrice.Value <= 0) { MessageBox.Show("لابد ان يكون مبلغ الايداع اكبر من صفر", "تاكيد"); return; }
                db.exceuteData("update Stock set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

                db.exceuteData("insert into Stock_Insert (Stock_ID , Money ,Date ,Name ,Type ,Reason ,From_) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' ,N'رصيد اضافى', N'" + txtreason.Text + "',N'"+txtFrom.Text+"') ", "تم الايداع بنجاح");
                onLoadScreen();
            }
        }

        private void btnFirst_Click(object sender, EventArgs e)
        {
            row = 0;
            Show();
            btnAdd.Enabled = false;
        }

        private void btnPrev_Click(object sender, EventArgs e)
        {
            if (row == 0)
            {
                tbl.Clear();
                tbl = db.readData("select count(Order_ID) from Stock_Insert", "");
                row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
                Show();
                btnAdd.Enabled = false;
            }
            else
            {


                row--;
                Show();
            }
        }

        private void btnNext_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Order_ID) from Stock_Insert", "");
            if (Convert.ToInt32(tbl.Rows[0][0]) - 1 == row)
            {
                row = 0;
                Show();
            }
            else
            {
                row++;
                Show();
            }
            btnAdd.Enabled = false;
        }

        private void btnLast_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Order_ID) from Stock_Insert", "");
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
            Show();
            btnAdd.Enabled = false;
        }

        private void btnEdit_Click(object sender, EventArgs e)
        {

        }
    }
}