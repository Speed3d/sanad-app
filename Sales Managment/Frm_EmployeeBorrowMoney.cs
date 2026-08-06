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
    public partial class Frm_EmployeeBorrowMoney : DevExpress.XtraEditors.XtraForm
    {
        public Frm_EmployeeBorrowMoney()
        {
            InitializeComponent();
        }
        Database db = new Database();
        DataTable tbl = new DataTable();
        private void AutoNumber()
        {
            tbl.Clear();
            tbl = db.readData("select max (Order_ID) from Employee_BorrowMoney", "");

            if ((tbl.Rows[0][0].ToString() == DBNull.Value.ToString()))
            {
                txtID.Text = "1";
            }
            else
            {
                txtID.Text = (Convert.ToInt32(tbl.Rows[0][0]) + 1).ToString();
            }
            NudPrice.Value = 1;
            txtname.Clear();
            txtNotes.Clear();
            txtCreditor.Clear();
            DtpDate.Text = DateTime.Now.ToShortDateString();
            DtpReminder.Text = DateTime.Now.ToShortDateString();
            rbtnNormal_CheckedChanged(null, null);
            try
            {
                cbxEmployee.SelectedIndex = 0;
            }
            catch (Exception) { }

        }

        //تحميل خانة الموظفين
        private void FillEmployee()
        {
            cbxEmployee.DataSource = db.readData("select * from Employee", "");
            cbxEmployee.DisplayMember = "Emp_Name";
            cbxEmployee.ValueMember = "Emp_ID";
        }

        //تحميل خانة الخزنات
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }
        //string stock_ID = "";
        private void Frm_EmployeeBorrowMoney_Load(object sender, EventArgs e)
        {
            try
            {
                FillEmployee();
                fillStock();
                AutoNumber();

            }
            catch (Exception) { }
            //stock_ID = Convert.ToString(Properties.Settings.Default.Stock_ID);
        }

        //لاختيار شخص عادي وغلق الموظف
        private void rbtnNormal_CheckedChanged(object sender, EventArgs e)
        {
            cbxEmployee.Enabled = false;
            txtname.Enabled = true;
        }

        //لاختيار موظف وغلق الشخص العادي
        private void rbtnEmployee_CheckedChanged(object sender, EventArgs e)
        {
            cbxEmployee.Enabled = true;
            txtname.Enabled = false;
        }

        //زر الاضافة
        private void btnAdd_Click(object sender, EventArgs e)
        {
            string d = DtpDate.Value.ToString("dd/MM/yyyy");
            string dReminder = DtpReminder.Value.ToString("dd/MM/yyyy");
            if ( cbxEmployee.Items.Count <= 0)
            {
                MessageBox.Show("من فضلك تاكيد من اكتمال بيانات الموظفين", "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            if (NudPrice.Value <= 0)
            {
                MessageBox.Show("لابد ان يكون المبلغ لا يقل عن 1", "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            if (txtCreditor.Text == "")
            {
                MessageBox.Show("من فضلك ادخل اسم الشخص المدين", "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            string name = txtname.Text;
            if (rbtnEmployee.Checked == true)
            { name = cbxEmployee.Text; }
            else
            {
                if (txtname.Text == "")
                {
                    MessageBox.Show("من فضلك ادخل اسم الشخص المدين", "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                txtname.Text = txtname.Text;
            }

            tbl.Clear();
            tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            if (NudPrice.Value > Convert.ToDecimal(tbl.Rows[0][1]))
            {
                MessageBox.Show("لا يمكن سحب قيمه اكبر من الموجوده فى الخزنة", "تاكيد");
                return;
            }
            if (rbtnEmployee.Checked == true)
            {
                db.exceuteData("insert into Employee_SalaryMinus (Emp_ID,Emp_Name ,Date ,Price,Pay) values (" + cbxEmployee.SelectedValue + " ,N'" + name + "' ,N'" + d + "' ," + NudPrice.Value + " ,'NO')", "");
            }
            db.exceuteData("insert into Stock_Pull (Stock_ID , Money ,Date ,Name ,Type ,Reason) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtCreditor.Text + "' ,N'سلف', N'" + txtNotes.Text + "') ", "");

            db.exceuteData("update Stock set Money=Money - " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");
            db.exceuteData("insert into Employee_BorrowMoney values ("+txtID.Text+" , N'"+txtCreditor.Text+"' ,N'"+name+"' ,N'"+d+"' ,N'"+dReminder+"' ,"+NudPrice.Value+" ,N'"+txtNotes.Text+"')", "تمت العملية بنجاح");


            AutoNumber();

        }

        private void label1_Click(object sender, EventArgs e)
        {

        }
    }
}