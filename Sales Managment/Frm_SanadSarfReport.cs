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
    public partial class Frm_SanadSarfReport : DevExpress.XtraEditors.XtraForm
    {
        public Frm_SanadSarfReport()
        {
            InitializeComponent();
        }
        Database db = new Database();
        DataTable tbl = new DataTable();

        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }

        private void Frm_SanadSarfReport_Load(object sender, EventArgs e)
        {
            try
            {
                //onLoadScreen();  // تحميل بيانات الخزنات
                fillStock();
            }
            catch (Exception) { }
            DtpFrom.Text = DateTime.Now.ToShortDateString();
            DtpTo.Text = DateTime.Now.ToShortDateString();
        }

        // كود زر البحث
        private void btnSearch_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                }
            }
            // اذا خانة البحث كان بها اسم يقوم ببحث عن اسم معين
            else
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                }
            }
            // اذا الجدول به مبالغ يقوم بجمعها
            if (tbl.Rows.Count >= 1)
            {
                DgvSearch.DataSource = tbl;
                decimal Sum = 0;
                for (int i = 0; i <= tbl.Rows.Count - 1; i++)
                {
                    Sum += Convert.ToDecimal(tbl.Rows[i][1]);
                }

                txtTotal.Text = Math.Round(Sum, 2).ToString();
            }
            // اذا الجدول ليس به مبالغ يضع مكانه صفر
            else
            { txtTotal.Text = "0"; }

        }


        //كود الحذف يحتاج ايضا حذف السطر المحدد وحذفه من الخزنة الرئيسية وعمل تحديث للمبلغ
        private void btnDelete_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            if (MessageBox.Show("هل انتا متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                db.exceuteData("delete from Stock_Pull where Order_ID ='" + DgvSearch.CurrentRow.Cells[0].Value + "'", "تم مسح البيانات المحددة بنجاح");
            }
        }

        private void cbxStock_SelectionChangeCommitted(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            if (tbl.Rows.Count <= 0)
            {
                db.exceuteData("insert into Stock values (" + cbxStock.SelectedValue + " , 0)", "");
                tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
            }
            else { }
        }

        private void groupBox1_Enter(object sender, EventArgs e)
        {

        }

        //كود طباعة المحدد
        private void Print()
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            DataTable tblRpt = new DataTable();

            int id = Convert.ToInt32(cbxStock.SelectedValue);

            tblRpt.Clear();
            // اذا الخزنة محددة يدخل الى الامر
            if (rbtnOneStock.Checked == true)
            {
                tblRpt = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        //حاسبة الشركة
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");
                        // حاسبتي الخاصة
                      //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-56B5KGI", "Sales_System");
                        rpt.SetDataSource(tblRpt);
                        // rpt.SetParameterValue("ID", id);
                        frm.crystalReportViewer1.ReportSource = rpt;

                        System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                        rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                        rpt.PrintToPrinter(1, true, 0, 0);
                        // frm.ShowDialog();
                    }
                    else if (Properties.Settings.Default.BuyPrintKind == "A4")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        //حاسبة الشركة
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");
                        // حاسبتي الخاصة
                       // rpt.SetDatabaseLogon("", "", @".\DESKTOP-56B5KGI", "Sales_System");
                        rpt.SetDataSource(tblRpt);
                        // rpt.SetParameterValue("ID", id);
                        frm.crystalReportViewer1.ReportSource = rpt;

                        System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                        rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                        // rpt.PrintToPrinter(1, true, 0, 0);
                        frm.ShowDialog();
                    }


                }
                catch (Exception) { }
            }
            else if (rbtnAllStock.Checked == true)
            {

            }
        }

        private void btnPtintSelect_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                Print();
            }
        }


        //كود طباعة الكل
        private void PrintAll()
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            DataTable tblRpt = new DataTable();

            tblRpt.Clear();
            //طباعة الكل

            tblRpt = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف',[Date] as 'تاريخ الصرف',[Name] as 'المسؤل عن الصرف',[Type] as 'نوع الصرف',[Too_] as 'صرف لــ',[Reason] as 'السبب',Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date,Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

            if (DgvSearch.Rows.Count >= 1)
            {
                if (rbtnAllStock.Checked == true)
                {
                    try
                    {
                        Frm_Print frm = new Frm_Print();

                        frm.crystalReportViewer1.RefreshReport();

                        if (Properties.Settings.Default.BuyPrintKind == "8CM")
                        {
                            RptSanadSarfReport rpt = new RptSanadSarfReport();
                            rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System"); 
                          //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-56B5KGI", "Sales_System");
                            rpt.SetDataSource(tblRpt);
                            // rpt.SetParameterValue("ID", id);
                            frm.crystalReportViewer1.ReportSource = rpt;

                            System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                            rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                            rpt.PrintToPrinter(1, true, 0, 0);
                            // frm.ShowDialog();
                        }
                        else if (Properties.Settings.Default.BuyPrintKind == "A4")
                        {
                            RptSanadSarfReport rpt = new RptSanadSarfReport();
                            rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");
                           // rpt.SetDatabaseLogon("", "", @".\DESKTOP-56B5KGI", "Sales_System");
                            rpt.SetDataSource(tblRpt);
                            // rpt.SetParameterValue("ID", id);
                            frm.crystalReportViewer1.ReportSource = rpt;

                            System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                            rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                            //rpt.PrintToPrinter(1, true, 0, 0);
                            frm.ShowDialog();
                        }


                    }
                    catch (Exception) { }
                }
                else if (rbtnOneStock.Checked == true)
                {

                }
            }
        }
        private void btnPrintAll_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintAll();
            }
        }

        //عند الضغط على خزنة محددة يمسح المحتوى للبحث من جديد
        private void rbtnOneStock_CheckedChanged(object sender, EventArgs e)
        {
            tbl.Clear();
            txtTotal.Clear();
        }

        //عند الضغط على كل الخزنات يمسح المحتوى للبحث من جديد
        private void rbtnAllStock_CheckedChanged(object sender, EventArgs e)
        {
            tbl.Clear();
            txtTotal.Clear();
        }
    }
}