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
    public partial class Frm_Sanad_Pull_Contractors_Report : DevExpress.XtraEditors.XtraForm
    {
        public Frm_Sanad_Pull_Contractors_Report()
        {
            InitializeComponent();
        }


        Database db = new Database();
        DataTable tbl = new DataTable();


        //تحميل الخزنات
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data_Contractors", "");
            cbxStock.DisplayMember = "Stock_Contractors_Name";
            cbxStock.ValueMember = "Stock_Contractors_ID";
        }


        // تحميلالصفحة
        private void Frm_Sanad_Pull_Contractors_Report_Load(object sender, EventArgs e)
        {
            try
            {
                // تحميل بيانات الخزنات
                fillStock();
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
            btnPrintContractors.Enabled = false;

            // اذا خانة البحث فارغة يقوم بالبحث بشكل عام 
            if (txtSearch.Text == "")
            {
                //بحث كل الخزنات بتاريخ محدد
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                    btnPrintAll.Enabled = true;
                }

                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Contractors.Stock_Contractors_ID = " + cbxStock.SelectedValue + "", "");
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
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                    btnPrintAll.Enabled = true;
                }

                // بحث خزنة محددة برقم وصل محدد في خانة رقم الوصل
                else if (rbtnOneStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Rec_Num like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Contractors.Stock_Contractors_ID = " + cbxStock.SelectedValue + "", "");
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


        // كود بحث اسم مقاول محدد
        private void btnSearchContractors_Click(object sender, EventArgs e)
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
                    MessageBox.Show(" اكتب اسم المقاول اولا ");
                    return;
                }

                // بحث خزنة محددة بتاريخ محدد
                else if (rbtnOneStock.Checked == true)
                {
                    MessageBox.Show(" اكتب اسم المقاول اولا ");
                    return;
                }

            }

            //  اذا خانة البحث كان بها اسم مقاول يقوم ببحث عن اسم المقاول في خانة اسم المقاول
            else
            {
                btnPrintContractors.Enabled = true;
                //بحث كل الخزنات بتاريخ محدد واسم مقاول محدد 
                if (rbtnAllStock.Checked == true)
                {
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and [Add_Contractors].Contractors_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");
                }

                // بحث خزنة محددة وبتاريخ محدد واسم مقاول محدد 
                else if (rbtnOneStock.Checked == true)
                {
                    btnPrintAll.Enabled = false;
                    tbl = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and [Add_Contractors].Contractors_Name like N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Contractors.Stock_Contractors_ID = " + cbxStock.SelectedValue + "", "");
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
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة',[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Contractors.Stock_Contractors_ID = " + cbxStock.SelectedValue + "", "");

                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
                        RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
            Print_Number();
        }


        // كود طباعة اسم مقاول
        private void Print_Contractors()
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
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة',[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Add_Contractors.[Contractors_Name] like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "' and Stock_Data_Contractors.Stock_Contractors_ID = " + cbxStock.SelectedValue + "", "");

                try
                {
                    Frm_Print frm = new Frm_Print();

                    frm.crystalReportViewer1.RefreshReport();

                    if (Properties.Settings.Default.BuyPrintKind == "8CM")
                    {
                        RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
                        RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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


        // زر طباعةالمقاول
        private void btnPrintContractors_Click(object sender, EventArgs e)
        {
            Print_Contractors();
        }

        // كود طباعة الكل
        private void Print_ALL()
        {
            string date1;
            string date2;
            date1 = DtpFrom.Value.ToString("yyyy-MM-dd");
            date2 = DtpTo.Value.ToString("yyyy-MM-dd");
            DataTable tblRpt = new DataTable();
            tblRpt.Clear();
            //طباعة الكل
            // اذا زر طباعة الرقم مفعل يطبع الكل مع او بدون رقم 
            if (btnPtintNumber.Enabled == true)
            {
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة',[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Rec_Num like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

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
                                RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
                                RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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

            // اذا زر طباعة اسم مقاول مفعل يطبع الكل مع اوبدون اسم مقاول
            else if ( btnPrintContractors.Enabled == true )

            {
                tblRpt = db.readData("SELECT[Rec_Num] as 'رقم الوصل',[Money] as 'المبلغ المصروف' ,[Add_Contractors].Contractors_Name as ' اسم المقاول ' ,[Date] as 'تاريخ الصرف' ,[Name] as 'المسؤل عن الصرف' ,[Reason] as 'التفاصيل' ,[Too] as 'صرف لــ' ,Stock_Data_Contractors.[Stock_Contractors_Name] as 'اسم الخزنة' ,Stock_Pull_Contractors.[Stock_ID] as 'رقم الخزنة',[Order_ID] as ' # ' FROM[dbo].[Stock_Pull_Contractors],Stock_Data_Contractors ,Add_Contractors where Stock_Data_Contractors.Stock_Contractors_ID = Stock_Pull_Contractors.Stock_ID and Stock_Pull_Contractors.Item_Contractors = Add_Contractors.Contractors_ID and Add_Contractors.[Contractors_Name] like  N'%" + txtSearch.Text + "%' and Convert(date, Date ,105 ) between '" + date1 + "' and '" + date2 + "'", "");

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
                                RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
                                RptSanad_ContractorsReport rpt = new RptSanad_ContractorsReport();
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
            Print_ALL();
        }



    }
}