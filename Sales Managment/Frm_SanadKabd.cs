using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Linq;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using OfficeOpenXml.FormulaParsing.Excel.Functions.Information;

namespace Sales_Managment
{
    public partial class Frm_SanadKabd : DevExpress.XtraEditors.XtraForm
    {
        public Frm_SanadKabd()
        {
            InitializeComponent();
        }

        Database db = new Database();
        DataTable tbl = new DataTable();


        private void AutoNumber()
        {
            tbl.Clear();
            tbl = db.readData("select max (Order_ID) from Stock_Insert", "");

            if ((tbl.Rows[0][0].ToString() == DBNull.Value.ToString()))
            {

                txtID.Text = "1";
            }
            else
            {

                txtID.Text = (Convert.ToInt32(tbl.Rows[0][0]) + 1).ToString();
            }
            NudPrice.Value = 1;
            DtpDate.Text = DateTime.Now.ToShortDateString();
            txtReason.Clear();
            txtName.Clear();
            txtFrom_To.Clear();
            TxNumber.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelete.Enabled = false;
            btnEdit.Enabled = false;

        }

        //تحميل خانة الخزنات
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }

        int row;

        //دالة شو لاستخدامها في الازرار لتحميل البيانات
        private void Show()
        {

            tbl.Clear();
            // جلب جميع البيانات من جدول Stock_Pull
            tbl = db.readData("select * from Stock_Insert", "");

            if (tbl.Rows.Count <= 0)
            {
                MessageBox.Show("لا يوجد بيانات فى هذه الشاشه");
                // إعادة تهيئة النموذج إذا لم يكن هناك بيانات
                AutoNumber();
            }
            else
            {
                try
                {
                    txtID.Text = tbl.Rows[row][0].ToString();
                    cbxStock.SelectedValue = tbl.Rows[row][1].ToString();
                    NudPrice.Value = Convert.ToDecimal(tbl.Rows[row][2]);

                    if (tbl.Rows[row][3] != DBNull.Value)
                    {
                        DtpDate.Value = Convert.ToDateTime(tbl.Rows[row][3]);
                    }
                    else
                    {
                        DtpDate.Value = DateTime.Now; // تعيين قيمة افتراضية إذا كان التاريخ فارغًا
                    }

                    txtName.Text= tbl.Rows[row][4].ToString();
                    //Type = Rows{row}[5]
                    txtReason.Text = tbl.Rows[row][6].ToString();
                    txtFrom_To.Text = tbl.Rows[row][7].ToString();
                    TxNumber.Text = tbl.Rows[row][8].ToString();


                }
                catch (Exception ex) 
                {
                    // عرض رسالة خطأ إذا حدث مشكلة أثناء عرض البيانات
                    MessageBox.Show("حدث خطأ أثناء عرض البيانات: " + ex.Message, "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);

                }
            }

            // تفعيل وتعطيل الأزرار بعد عرض البيانات
            btnAdd.Enabled = false;
            btnNew.Enabled = true;
            btnDelete.Enabled = true;
            btnEdit.Enabled = true;
        } 

        string stock_ID = "";

        private void Frm_SanadKabd_Load(object sender, EventArgs e)
        {
            AutoNumber();
            stock_ID = Convert.ToString(Properties.Settings.Default.Stock_ID);
            fillStock();
            btnEdit.Enabled= false;
        }

        //كود الطباعة مع الحفظ وقف حاليا

        private void Print()
        {
            int id = Convert.ToInt32(txtID.Text);
            DataTable tblRpt = new DataTable();

            tblRpt.Clear();
            tblRpt = db.readData("SELECT [Order_ID] as 'رقم العملية' ,[Name] as 'اسم المسؤل عن القبض',[Price] as 'المبلغ',[Date] as 'تاريخ العملية',[From_] as 'قبض المبلغ الى ',[Reason] as 'السبب' FROM [dbo].[Sanad_Kabd] where Order_ID=" + id + "", "");
            try
            {
                Frm_Print frm = new Frm_Print();

                frm.crystalReportViewer1.RefreshReport();

                RptSanadKabd rpt = new RptSanadKabd();


                rpt.SetDatabaseLogon("", "", @".\SQLEXPRESS", "Sales_System");
                rpt.SetDataSource(tblRpt);
                rpt.SetParameterValue("ID", id);
                frm.crystalReportViewer1.ReportSource = rpt;

                System.Drawing.Printing.PrintDocument printDocument = new System.Drawing.Printing.PrintDocument();
                rpt.PrintOptions.PrinterName = printDocument.PrinterSettings.PrinterName;
                //rpt.PrintToPrinter(1, true, 0, 0);
                frm.ShowDialog();
            }
            catch (Exception) { }
        }

        //  زر و كود اضافة ايداع او قبض 
        private void btnAdd_Click(object sender, EventArgs e)
        {
            try
            {
                if (txtFrom_To.Text == "" || txtName.Text == "" || TxNumber.Text == "" || txtReason.Text == "")
                {
                    MessageBox.Show("من فضلك اكمل البيانات");
                    return;
                }
                // تم تحديث صيغة التاريخ لتتوافق مع صيغة التاريخ المعدل Date الجديد في Sql 
                //التعديل بتاريخ 2025-07-17
                string d = DtpDate.Value.ToString("yyyy-MM-dd");

                // decimal stock_Money = 0;
                try
                {
                    tbl = db.readData("select * from Stock where Stock_ID=" + cbxStock.SelectedValue + "", "");
                }
                catch (Exception) { }

                if  //(NudPrice.Value > stock_Money)
                    (NudPrice.Value > Convert.ToDecimal(tbl.Rows[0][1]))
                {
                    MessageBox.Show(" لايوجد رصيد كافي فى الخزنة لاجراء العملية");
                    return;
                }
                else
                {
                    db.exceuteData("update stock set Money=Money - " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

                    db.exceuteData("insert into Stock_Insert (Stock_ID , Money ,Date ,Name ,Type ,Reason ,From_ ,Rec_Num ) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' ,N'ايداع - رصيد إضافي', N'" + txtReason.Text + "',N'" + txtFrom_To.Text + "' , N'" + TxNumber.Text + "' ) ", "تم صرف المبلغ بنجاح");
                    AutoNumber();
                }

            }
            catch (Exception ex)
            {
                // في حال حدوث أي خطأ آخر، سيتم عرضه هنا
                MessageBox.Show("فشلت عملية إضافة السجل.\n\n" + "تفاصيل الخطأ: " + ex.Message,
                                "خطأ فني", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        private void btnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }


        //كود الحذف النهائي من الجدول و الخزنة و عمل تحديث للمبلغ
        private void btnDelete_Click(object sender, EventArgs e)
        {
            try
            {
                if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                {
                    db.readData("delete from Stock_Insert  where Order_ID=" + txtID.Text + "", "تم مسح البيانات بنجاح");
                    db.exceuteData("update Stock set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");
                    AutoNumber();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("حدث خطأ غير متوقع أثناء عملية التعديل.\n\n" + "تفاصيل الخطأ: " + ex.Message,
                                "خطأ فني", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // زر و كود التعديل
        private void btnEdit_Click(object sender, EventArgs e)
        {
            try
            {
                // 1. التحقق من المدخلات
                if (string.IsNullOrWhiteSpace(txtFrom_To.Text) || string.IsNullOrWhiteSpace(txtName.Text) ||
                    string.IsNullOrWhiteSpace(TxNumber.Text) || string.IsNullOrWhiteSpace(txtReason.Text))
                {
                    MessageBox.Show("من فضلك، تأكد من إكمال كافة البيانات المطلوبة.", "بيانات ناقصة", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                // 2. استرجاع المبلغ القديم من قاعدة البيانات
                decimal oldMoney = 0;
                DataTable tblOld = db.readData("SELECT Money FROM Stock_Insert WHERE Order_ID = " + txtID.Text, "");
                if (tblOld != null && tblOld.Rows.Count > 0)
                {
                    oldMoney = Convert.ToDecimal(tblOld.Rows[0][0]);
                }
                else
                {
                    MessageBox.Show("لم يتم العثور على السجل القديم المراد تعديله.", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                // 3. التأكد من وجود رصيد كافٍ في الخزنة بعد التعديل
                decimal stockMoney = 0;
                DataTable tblStock = db.readData("SELECT Money FROM Stock WHERE Stock_ID = " + cbxStock.SelectedValue, "");
                if (tblStock != null && tblStock.Rows.Count > 0)
                {
                    stockMoney = Convert.ToDecimal(tblStock.Rows[0][0]);
                }

                // الرصيد المتاح = الرصيد الحالي + المبلغ القديم الذي سيعود للخزنة
                if (NudPrice.Value > (stockMoney + oldMoney))
                {
                    MessageBox.Show("الرصيد في الخزنة غير كافٍ لإتمام هذه العملية بعد التعديل.", "رصيد غير كافٍ", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    return;
                }

                // 4. تنفيذ عمليات التحديث في قاعدة البيانات
                string d = DtpDate.Value.ToString("yyyy-MM-dd"); // استخدام تنسيق تاريخ متوافق مع SQL

                // أولاً: إعادة المبلغ القديم إلى الخزنة
                db.exceuteData("UPDATE Stock SET Money = Money - " + oldMoney + " WHERE Stock_ID = " + cbxStock.SelectedValue, "");

                // ثانياً: خصم المبلغ الجديد من الخزنة
                db.exceuteData("UPDATE Stock SET Money = Money + " + NudPrice.Value + " WHERE Stock_ID = " + cbxStock.SelectedValue, "");

                // ثالثاً: تحديث بيانات السجل نفسه

                string updateQuery = "UPDATE Stock_Insert SET " +
                             "Stock_ID = " + cbxStock.SelectedValue + ", " +
                             "Money = " + NudPrice.Value + ", " +
                             "Date = N'" + d + "', " +
                             "Name = N'" + txtName.Text.Trim() + "', " +
                             "Reason = N'" + txtReason.Text.Trim() + "', " +
                             "From_ = N'" + txtFrom_To.Text.Trim() + "', " +
                             "Rec_Num = N'" + TxNumber.Text.Trim() + "' " +
                             "WHERE Order_ID = " + txtID.Text;

                // ✔️ **التعديل الأول: استدعاء الدالة بدون رسالة**
                db.exceuteData(updateQuery, ""); // مررنا نصًا فارغًا للرسالة لتنفيذ الأمر بصمت

                // ✔️ **التعديل الثاني: إظهار رسالة واحدة ومخصصة**
                MessageBox.Show("تم تعديل البيانات بنجاح.", "نجاح", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // ✔️ **التعديل الثالث: استدعاء AutoNumber للتهيئة لعملية جديدة**
                AutoNumber();
            }
            catch (Exception ex)
            {
                MessageBox.Show("حدث خطأ غير متوقع أثناء عملية التعديل.\n\n" + "تفاصيل الخطأ: " + ex.Message,
                                "خطأ فني", MessageBoxButtons.OK, MessageBoxIcon.Error);
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
                tbl = db.readData("select count(Order_ID) from Stock_Insert", "");
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
        }

        private void btnLast_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Order_ID) from Stock_Insert", "");
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1; // الانتقال إلى السجل الأخير
            Show(); // عرض السجل
        }
    }
}