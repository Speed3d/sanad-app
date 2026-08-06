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
    public partial class Frm_SanadKabdReport : DevExpress.XtraEditors.XtraForm
    {
        public Frm_SanadKabdReport()
        {
            InitializeComponent();
        }
        Database db = new Database();
        DataTable tbl = new DataTable();


        private void fillStock() // ملئ بيانات الخزنات هنا
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }

        private void Frm_SanadReport_Load(object sender, EventArgs e)
        {
            try
            {
                //onLoadScreen();  // تحميل بيانات الخزنات
                fillStock();
            }
            catch (Exception) { }
            DtpFrom.Text = DateTime.Now.ToShortDateString();
            DtpTo.Text = DateTime.Now.ToShortDateString();
            btnDelete.Enabled = false;
        }

        //كود الحذف يحتاج ايضا حذف السطر المحدد وحذفه من الخزنة الرئيسية وعمل تحديث للمبلغ
        private void btnDelete_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            
            if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                 db.exceuteData("delete from Stock_Insert where Order_ID ='" + DgvSearch.CurrentRow.Cells[0].Value + "'", "تم مسح البيانات المحددة بنجاح");

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


        //كود بحث كل الخزنات او خزنة محددة
        private void btnSearch_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPrintNum.Enabled = false;
            btnPtintSelectStok.Enabled = true;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب' , Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM [dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

                }
                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب' , Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM [dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

                }
            }

            // اذا خانة البحث كان بها اسم يقوم ببحث عن في خانة السبب
            else
            {
                //بحث كل الخزنات بتاريخ محدد في خانة السبب
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض' ,[Date] as 'تاريخ القبض' ,[From_] as 'قبض مــن ' ,[Reason] as 'السبب' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                //  MessageBox.Show("الرجاء اختر خزنة للبحث باسم او رقم معين");
                }
                //بحث خزنة محددة و بتاريخ محدد في خانة السبب
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب' , Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
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

        // كود طباعة خزنة محددة وسبب محد
        private void PrintSelectStok()
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
                tblRpt = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب', Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadKabdReport rpt = new RptSanadKabdReport();
                        //حاسبة الابتوب
                      //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

                        rpt.SetDataSource(tblRpt);
                        // rpt.SetParameterValue("ID", id);
                        frm.crystalReportViewer1.ReportSource = rpt;

                        System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                        rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                        //   rpt.PrintToPrinter(1, true, 0, 0);
                        frm.ShowDialog();
                    }
                    else if (Properties.Settings.Default.BuyPrintKind == "A4")
                    {
                        RptSanadKabdReport rpt = new RptSanadKabdReport();
                        //حاسبة  الابتوب 
                      //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

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

        // زر طباعة محددة
        private void btnPtintSelectStok_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintSelectStok();
            }
        }



        // كود طباعة كل الخزنات 
        private void PrintAll()
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            DataTable tblRpt = new DataTable();

            tblRpt.Clear();
            //طباعة الكل

            tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض' ,[Date] as 'تاريخ القبض' ,[From_] as 'قبض مــن ' ,[Reason] as 'السبب' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

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
                            RptSanadKabdReport rpt = new RptSanadKabdReport();
                          //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                            rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

                            rpt.SetDataSource(tblRpt);
                            // rpt.SetParameterValue("ID", id);
                            frm.crystalReportViewer1.ReportSource = rpt;

                            System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                            rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                            //  rpt.PrintToPrinter(1, true, 0, 0);
                            frm.ShowDialog();
                        }
                        else if (Properties.Settings.Default.BuyPrintKind == "A4")
                        {
                            RptSanadKabdReport rpt = new RptSanadKabdReport();
                          //  rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                            rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

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

        // زر طباعة الكل
        private void btnPrintAll_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintAll();
            }
        }



        // كود طباعة خزنة محدة ورقم لمحدد
        private void PrintNumber()
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
                tblRpt = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب', Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadKabdReport rpt = new RptSanadKabdReport();
                        //حاسبة الابتوب
                       // rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

                        rpt.SetDataSource(tblRpt);
                        // rpt.SetParameterValue("ID", id);
                        frm.crystalReportViewer1.ReportSource = rpt;

                        System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                        rpt.PrintOptions.PrinterName = Properties.Settings.Default.PrinterName;
                        //   rpt.PrintToPrinter(1, true, 0, 0);
                        frm.ShowDialog();
                    }
                    else if (Properties.Settings.Default.BuyPrintKind == "A4")
                    {
                        RptSanadKabdReport rpt = new RptSanadKabdReport();
                        //حاسبة  الابتوب 
                       // rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-160PK05", "Sales_System");

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

        //  كود بحث خزنة محدة وبرقم محدد
        private void btnSearchNum_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPtintSelectStok.Enabled = false;
            btnPrintNum.Enabled = true;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                // لا ينفذ اي شي
            }

            // اذا خانة البحث كان بها رقم او اسم يقوم ببحث عن اسم او رقم معين
            else
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    //  لا ينفذ اي شي
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض' ,[Date] as 'تاريخ القبض' ,[From_] as 'قبض مــن ' ,[Reason] as 'السبب' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

                }
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT [Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المقبوض',[Date] as 'تاريخ القبض', [Type] as 'نوع القبض',[From_] as 'قبض مــن',[Reason] as 'السبب' , Stock_Data.[Stock_Name] as 'اسم الخزنة',Stock_Insert.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Insert],Stock_Data where Stock_Data.Stock_ID = Stock_Insert.Stock_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
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


        // زر طباعة خزنة محدة ورقم محدد
        private void btnPrintNum_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintNumber();
            }
        }

    }
}