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
    public partial class Frm_StockAddMoneyReport : DevExpress.XtraEditors.XtraForm
    {
        
        public Frm_StockAddMoneyReport()
        {
            InitializeComponent();
        }
        Database db = new Database();
        DataTable tbl = new DataTable();

        private void onLoadScreen()  // تحديد وتحميل جميع الخزنات وتفاصيلها هنا
        {

            fillStock();
            tbl.Clear();
            tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            if (tbl.Rows.Count <= 0)
            {
                db.exceuteData("insert into Stock values (" + cbxStock.SelectedValue + " , 0)", "");
                tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            }
           else { }
        }
        private void fillStock() // ملئ بيانات الخزنات هنا
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }


        private void Frm_StockAddMoneyReport_Load(object sender, EventArgs e)
        {
            try
            {
                onLoadScreen();  // تحميل بيانات الخزنات
            }
            catch (Exception) { }

            DtpFrom.Text = DateTime.Now.ToShortDateString();
            DtpTo.Text = DateTime.Now.ToShortDateString();
            
        }

        private void btnSearch_Click(object sender, EventArgs e)
        {
            {
                string date1;
                string date2;
                date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
                date2 = DtpTo.Value.ToString("yyyy-MM-dd");
                tbl.Clear();
                if (rbtnAllStock.Checked == true) //بحث كل الخزنات بتاريخ محدد
                {
                    tbl = db.readData("SELECT [Order_ID] as 'رقم العملية',Stock_Data.Stock_Name as 'اسم الخزنة',[Money] as 'المبلغ',[Date] as 'تاريخ العملية',[Name] as 'المسؤل عن الايداع' ,[Type] as 'نوع لاايداع',[Reason] as 'السبب' FROM [dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID =[Stock_Insert].Stock_ID and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "' ", "");
                }
                else if (rbtnOneStock.Checked == true)  // بحث خزنة محددة بتاريخ محدد
                {
                    tbl = db.readData("SELECT [Order_ID] as 'رقم العملية',Stock_Data.Stock_Name as 'اسم الخزنة',[Money] as 'المبلغ',[Date] as 'تاريخ العملية',[Name] as 'المسؤل عن الايداع' ,[Type] as 'نوع لاايداع',[Reason] as 'السبب' FROM [dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID =[Stock_Insert].Stock_ID and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                }
            }
                                                          
            if (tbl.Rows.Count >= 1)
            {
                DgvSearch.DataSource = tbl;
                decimal Sum = 0;
                for (int i = 0; i <= tbl.Rows.Count - 1; i++)
                {
                    Sum += Convert.ToDecimal(tbl.Rows[i][2]);
                }

                txtTotal.Text = Math.Round(Sum, 2).ToString();
            }
            else
            { txtTotal.Text = "0"; }
        }


        //مسح جميع البيانات في الجدول بتاريخ محدد
        private void btnDelete_Click(object sender, EventArgs e) 

        {
            //string date1;
            //string date2;
            //date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            //date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            //if (MessageBox.Show("هل انتا متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            //{
            //    db.exceuteData("delete from Stock_Insert where Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "تم مسح البيانات بنجاح");

            //}
        }

        //مسح السطر المحدد من DataGridView
        private void btndelselect_Click(object sender, EventArgs e)
        {
            
            if (MessageBox.Show("هل متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
              db.exceuteData("delete from Stock_Insert where Order_ID ='" + DgvSearch.CurrentRow.Cells[0].Value + "'", "تم مسح البيانات بنجاح");
            }
        }             

        private void cbxStock_SelectionChangeCommitted(object sender, EventArgs e) // تحميل وتغعيل البيانات داخل cbxStok
        {
            tbl.Clear();
            tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
           
        }
        
    }
}