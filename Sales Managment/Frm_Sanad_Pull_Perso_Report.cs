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
    public partial class Frm_Sanad_Pull_Perso_Report : DevExpress.XtraEditors.XtraForm
    {
        public Frm_Sanad_Pull_Perso_Report()
        {
            InitializeComponent();
        }

        Database db = new Database();
        DataTable tbl = new DataTable();

        //تحميل خانة الخزنات
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data_Personal", "");
            cbxStock.DisplayMember = "Stock_Personal_Name";
            cbxStock.ValueMember = "Stock_Personal_ID";
        }

        // تحميل خانة الشركاء
        private void fillPersonalTybe()
        {
            cbxAddType.DataSource = db.readData("select * from Add_Personal", "");
            cbxAddType.DisplayMember = "Personal_Name";
            cbxAddType.ValueMember = "Personal_ID";
        }


        //  تحميل الصفحة
        private void Frm_Sanad_Pull_Perso_Report_Load(object sender, EventArgs e)
        {
            try
            {
                // تحميل بيانات الخزنات
                fillStock();
                fillPersonalTybe();
            }
            catch (Exception) { }
            DtpFrom.Text = DateTime.Now.ToShortDateString();
            DtpTo.Text = DateTime.Now.ToShortDateString();
            btnDelete.Enabled = false;
        }

        //  كود بحث رقم محدد
        private void btnSearchNumber_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPrintPersonal.Enabled = false;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            { 
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                    btnPrintAll.Enabled = true;
                }

                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Personal.Stock_Personal_ID = " + cbxStock.SelectedValue + "", "");
                    btnPrintAll.Enabled = false;
                    btnPtintNumber.Enabled = true;
                }
            }

            //  اذا خانة البحث كان بها رقم يقوم ببحث عن رقم 
            else
            {
                btnPtintNumber.Enabled = true;
                //بحث كل الخزنات برقم وصل محدد في خانة رقم الوصل
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                    btnPrintAll.Enabled = true;
                }

                // بحث خزنة محددة برقم وصل محدد في خانة رقم الوصل
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Personal.Stock_Personal_ID = " + cbxStock.SelectedValue + "", "");
                    btnPrintAll.Enabled = false;
                    btnPtintNumber.Enabled = true;
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

        // كود بحث اسم شريك محدد
        private void btnSearchPersonal_Click(object sender, EventArgs e)
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            tbl.Clear();
            btnPtintNumber.Enabled = false;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    MessageBox.Show(" اكتب اسم الشريك اولا ");
                    return;
                    //   tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data ,Add_Personal where Stock_Data.Stock_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }

                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    MessageBox.Show(" اكتب اسم الشريك اولا ");
                    return;
                    //  tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data ,Add_Personal where Stock_Data.Stock_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                }

            }

            //  اذا خانة البحث كان بها اسم شريك يقوم ببحث عن اسم الشريك في خانة اسم الشريك
            else
            {
                btnPrintPersonal.Enabled = true;
                //بحث كل الخزنات بتاريخ محدد واسم شريك محدد 
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and [Add_Personal].Personal_Name like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }

                // بحث خزنة محددة وبتاريخ محدد واسم شريك محدد 
                else if (rbtnOneStock.Checked == true)
                {
                    btnPrintAll.Enabled = false;
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and [Add_Personal].Personal_Name like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Personal.Stock_Personal_ID = " + cbxStock.SelectedValue + "", "");
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

                // من هنا تبدا التجربة

                  try
                  {
                    decimal totalInsert_Personal = 0;
                    DataTable tblCkeck = new DataTable();
                    tblCkeck.Clear();
                    // tblCkeck = db.readData("select * from Stock_Insert_Personal where Item_Personal=" + cbxAddType.SelectedValue + "", "");
                    for (int i = 0; i <= tblCkeck.Rows.Count - 1; i++)
                    {
                        totalInsert_Personal += Convert.ToDecimal(tblCkeck.Rows[i][2]);
                    }
                    texInsert_Personal.Text = (Math.Round(totalInsert_Personal, 2)).ToString();

                    Text_Total_Insert.Text = (Convert.ToDecimal(txtTotal.Text) - Convert.ToDecimal(texInsert_Personal.Text)).ToString();
                  
                }
                  catch (Exception)
                  {

                  }
                // للتجربة

            }

            // اذا الجدول ليس به مبالغ يضع مكانه صفر
            else
            { txtTotal.Text = "0"; }
        }

        private void btnDelete_Click(object sender, EventArgs e)
        {
            //string date1;
            //string date2;
            //date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            //date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            //if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            //{
            //    db.exceuteData("delete from Stock_Pull_Personal where Money ='" + DgvSearch.CurrentRow.Cells[0].Value + "'", "تم مسح البيانات المحددة بنجاح");
            //    db.exceuteData("update Stock set Money=Money + " + DgvSearch.CurrentRow.Cells[0].Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

            //}
        }

        // كود طباعة رقم محدد
        private void Print_Number()
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
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' ,[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data_Personal.Stock_Personal_ID = " + cbxStock.SelectedValue + "", "");
               // tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Type].Type_Name as ' التصنيف ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'السبب' ,[Too_] as 'صرف لــ' ,[CloseSafe] as 'نوع الصرف في المشروع' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull],Stock_Data ,Add_Type where Stock_Data.Stock_ID = Stock_Pull.Stock_ID and Stock_Pull.Item_Type = Add_Type.Type_ID and Reason like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data.Stock_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                       frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                        //حاسبة الابتوب
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                        RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                        // حاسبتي الابتوب
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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

        // زر طباعة رقم محدد
        private void btnPtintNumber_Click(object sender, EventArgs e)
        {
            //   SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' ,[Order_ID] as 'رقم العملية' FROM[dbo].[Stock_Pull_Personal],Stock_Data ,Add_Personal where Stock_Data.Stock_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID
            Print_Number();
        }

        // كود طباعة اسم شريك
        private void Print_Personal()
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
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,Add_Personal.[Personal_Name] as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' ,[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Add_Personal.[Personal_Name] like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'and Stock_Data_Personal.Stock_Personal_ID = " + cbxStock.SelectedValue + "", "");
                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                        //حاسبة الابتوب
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                        RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                        // حاسبتي الابتوب
                        rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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

        // زر طباعةالشريك
        private void btnPrintPersonal_Click(object sender, EventArgs e)
        {
            Print_Personal();
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
            // اذا زر طباعة الرقم مفعل يطبع الكل مع او بدون رقم 
            if (btnPtintNumber.Enabled ==true )
            {

                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Personal.[Stock_Personal_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' ,[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

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
                                RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                                rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                                RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                                rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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

            // اذا زر طباعة اسم شريك مفعل يطبع الكل مع اوبدون اسم شريك
            else if (btnPrintPersonal.Enabled == true)
            {
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Personal].Personal_Name as ' اسم الشريك ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Personal.[Stock_Name] as 'اسم الخزنة' ,Stock_Pull_Personal.[Stock_ID] as 'رقم الخزنة' ,[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Personal],Stock_Data_Personal ,Add_Personal where Stock_Data_Personal.Stock_Personal_ID = Stock_Pull_Personal.Stock_ID and Stock_Pull_Personal.Item_Personal = Add_Personal.Personal_ID and Add_Personal.[Personal_Name] like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
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
                                RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                                rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
                                RptSanad_PersonalReport rpt = new RptSanad_PersonalReport();
                                rpt.SetDatabaseLogon("", "", @".\DESKTOP-MUNJ5T0", "Sales_System");
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
 
        }


        // زر طباعة الكل
        private void btnPrintAll_Click(object sender, EventArgs e)
        {
            PrintAll();
        }

        private void CbxAddType_SelectionChangeCommitted(object sender, EventArgs e)
        {
            // شغال ولكن مع بوكس الشركاء
            //try
            //{
            //    decimal totalInsert_Personal = 0;
            //    DataTable tblCkeck = new DataTable();
            //    tblCkeck.Clear();
            //    tblCkeck = db.readData("select * from Stock_Insert_Personal where Item_Personal=" + cbxAddType.SelectedValue + "", "");

            //    for (int i = 0; i <= tblCkeck.Rows.Count - 1; i++)
            //    {
            //        totalInsert_Personal += Convert.ToDecimal(tblCkeck.Rows[i][2]);
            //    }
            //    texInsert_Personal.Text = (Math.Round(totalInsert_Personal, 2)).ToString();

            //    Text_Total_Insert.Text = (Convert.ToDecimal(txtTotal.Text) - Convert.ToDecimal(texInsert_Personal.Text)).ToString();

            //}
            //catch (Exception) { }
        }
    }
}