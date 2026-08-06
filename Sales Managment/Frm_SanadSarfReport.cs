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


        //تحميل خانة الخزنات
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
            btnDelete.Enabled = false;
        }

        //  البحث في خانةالتفاصيل
        private void btnSearch_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
          //  DgvSearch.Columns[4].DefaultCellStyle.Format = ("yyyy-MM-dd"); مشتغل تعديل ستايل التاريخ
            tbl.Clear();
            btnPtintSelect.Enabled = true;
            btnPrintSelect01.Enabled = false;
            btnPrintNumber.Enabled = false;
            btnPrintSearchDrainage.Enabled = false;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                   tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[Order_ID] as 'رقم العملية' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[Order_ID] as 'رقم العملية' ,[CloseSafe] as 'نوع الصرف في المشروع'  ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                }
            }
            //  اذا خانة البحث كان بها اسم يقوم ببحث عن اسم معين في خانة السبب
            else
            {
                //بحث كل الخزنات بتاريخ وتصنيف محدد و اسم محدد في خانة السبب
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[Order_ID] as 'رقم العملية' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة وبتاريخ محدد واسم محدد في خانة السبب
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[Order_ID] as 'رقم العملية' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
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
            //string date1;
            //string date2;
            //date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            //date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            //if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            //{
            //    db.exceuteData("delete from Stock_Pull where Money ='" + DgvSearch.CurrentRow.Cells[2].Value + "'", "تم مسح البيانات المحددة بنجاح");
            //    db.exceuteData("update Stock set Money=Money + " + DgvSearch.CurrentRow.Cells[2].Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

            //}



        }



        private void cbxStock_SelectionChangeCommitted(object sender, EventArgs e)
        {
            tbl.Clear();
            txtTotal.Clear();
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


        //كود طباعة خزنة محددة وتفاصيل محددة 
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
            //   tblRpt = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Type] as 'نوع الصرف' ,[Too_] as 'صرف لــ' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                 tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        //حاسبة الابتوب
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
                    else if (Properties.Settings.Default.BuyPrintKind == "A4")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الابتوب
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


        // زر طباعة خزنة محددة وتفاصيل محددة
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

            tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

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
                            RptSanadSarfReport rpt = new RptSanadSarfReport();
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


     //------------------------------------------------------------------------------------------

        //  البحث في خانة التصنيف
        private void btnSearchType_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPrintSelect01.Enabled = true;
            btnPrintNumber.Enabled = false;
            btnPtintSelect.Enabled = false;
            btnPrintSearchDrainage.Enabled = false;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //لا ينفذاي شي
            }
            //  اذا خانة البحث كان بها اسم يقوم ببحث عن اسم معين في خانة التصنيف
            else
            {
                //بحث كل الخزنات بتاريخ وتصنيف محدد و اسم محدد في خانة التصنيف
                if (rbtnAllStock.Checked == true)
                {
                 // tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Type] as 'نوع الصرف' ,[Too_] as 'صرف لــ' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة وبتاريخ محدد واسم محدد في خانة التصنيف
                else if (rbtnOneStock.Checked == true)
                {
                 //   tbl = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Type] as 'نوع الصرف' ,[Too_] as 'صرف لــ' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

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


        //كود طباعة خزنة محددة وتصنيف محدد 
        private void PrintType()
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

             //  tblRpt = db.readData("SELECT[Order_ID] as 'رقم العملية',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Type] as 'نوع الصرف' ,[Too_] as 'صرف لــ' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
               tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and [Add_Type].Type_Name like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")  
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
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
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
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


        // زر طباعة خزنة محددة وتصنيف
        private void btnPrintSelect01_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintType();
            }
        }

     //------------------------------------------------------------------------------------------

        // البحث في نوع الصرف
        private void btnSearchDrainageType_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPrintSearchDrainage.Enabled = true;
            btnPrintNumber.Enabled = false;
            btnPtintSelect.Enabled = false;
            btnPrintSelect01.Enabled = false;
            // اذا خانة البحث فارغة يقوم لا يبحث اي شي 
            if (txtSearch.Text == "")
            {
                //لا ينفذاي شي
            }
            //  اذا خانة البحث كان بها اسم او رقم يقوم بالحث في نوع صرف 
            else
            {
                //بحث كل الخزنات بتاريخ وتصنيف محدد و اسم محدد في خانة التصنيف
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and CloseSafe like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة وبتاريخ محدد واسم محدد في خانة التصنيف
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and CloseSafe like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

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

        // كود طباعة خزنة محددة ونوع صرف     
        private void PrintSearchDrainage()
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

                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and CloseSafe like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
                       // rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
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

        // زر طباعة خزنة محددة ونوع صرف محدد
        private void btnPrintSearchDrainage_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintSearchDrainage();
            }
        }

     //------------------------------------------------------------------------------------------

        // بحث في خانة رقم الوصل
        private void btnSearchNumper_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPrintNumber.Enabled = true;
            btnPrintSearchDrainage.Enabled = false;
            btnPtintSelect.Enabled = false;
            btnPrintSelect01.Enabled = false;
            
            // اذا خانة البحث فارغة يقوم لا يبحث اي شي 
            if (txtSearch.Text == "")
            {
                //لا ينفذاي شي
            }
            //  اذا خانة البحث كان بها اسم او رقم يقوم بالحث في الرقم 
            else
            {
                //بحث كل الخزنات بتاريخ ورقم محدد 
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }
                // بحث خزنة محددة وبتاريخ محدد واسم او رقم محدد 
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,[Order_ID] as 'رقم العملية' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

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


        // كود طباعة خزنة محددة ورقم وصل محدد
        private void PrintSearchNumper()
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

                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");

                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
                        // rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                        RptSanadSarfReport rpt = new RptSanadSarfReport();
                        // حاسبتي الخاصة
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


        // زر طباعة خزنة محددة ورقم وصل محدد
        private void btnPrintNumber_Click(object sender, EventArgs e)
        {
            if (DgvSearch.Rows.Count >= 1)
            {
                PrintSearchNumper();
            }
            
        }

    }
}