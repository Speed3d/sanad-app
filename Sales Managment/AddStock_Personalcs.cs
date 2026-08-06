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
    public partial class AddStock_Personalcs : DevExpress.XtraEditors.XtraForm
    {
        public AddStock_Personalcs()
        {
            InitializeComponent();
        }

        Database db = new Database();
        DataTable tbl = new DataTable();


        private void AutoNumber()
        {
            tbl.Clear();
            tbl = db.readData("select max (Stock_Personal_ID) from Stock_Data_Personal", "");

            if ((tbl.Rows[0][0].ToString() == DBNull.Value.ToString()))
            {
                txtID.Text = "1";
            }
            else
            {
                txtID.Text = (Convert.ToInt32(tbl.Rows[0][0]) + 1).ToString();
            }

            txtName.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelete.Enabled = false;
            btnSave.Enabled = false;
        }


        int row;

        private void Show()
        {
            tbl.Clear();
            tbl = db.readData("select * from Stock_Data_Personal", "");

            if (tbl.Rows.Count <= 0)
            {
                MessageBox.Show("لا يوجد بيانات فى هذه الشاشه");
            }
            else
            {
                txtID.Text = tbl.Rows[row][0].ToString();
                txtName.Text = tbl.Rows[row][1].ToString();
            }

            btnAdd.Enabled = false;
            btnNew.Enabled = true;
            btnDelete.Enabled = true;
            btnSave.Enabled = true;
        }


        private void AddStock_Personalcs_Load(object sender, EventArgs e)
        {
            AutoNumber();
        }


        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (txtName.Text == "")
            {
                MessageBox.Show("من فضلك ادخل اسم الخزنة");
                return;
            }
            db.exceuteData("insert into Stock_Data_Personal Values (" + txtID.Text + " ,N'" + txtName.Text + "')", "تم الادخال بنجاح");

            AutoNumber();
        }


        private void btnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }


        private void btnSave_Click(object sender, EventArgs e)
        {
            if (txtName.Text == "")
            {
                MessageBox.Show("من فضلك ادخل اسم الخزنة");
                return;
            }
            db.exceuteData("update  Stock_Data_Personal set  Stock_Personal_Name=N'" + txtName.Text + "' where Stock_Personal_ID=" + txtID.Text + " ", "تم التعديل بنجاح");

            AutoNumber();
        }


        private void btnDelete_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                db.readData("delete from Stock_Data_Personal where Stock_Personal_ID=" + txtID.Text + "", "تم المسح بنجاح");
                AutoNumber();
            }
        }


        private void btnFirst_Click(object sender, EventArgs e)
        {
            row = 0;
            Show();
        }


        private void btnPrev_Click(object sender, EventArgs e)
        {
            if (row == 0)
            {
                tbl.Clear();
                tbl = db.readData("select count(Stock_Personal_ID) from Stock_Data_Personal", "");
                row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
                Show();
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
            tbl = db.readData("select count(Stock_Personal_ID) from Stock_Data_Personal", "");
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
        }


        private void btnLast_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Stock_Personal_ID) from Stock_Data_Personal", "");
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
            Show();
        }
    }
}