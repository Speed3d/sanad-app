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
            txtreason.Clear();
            txtName.Clear();
            txtFrom_To.Clear();
            TxNumber.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelet.Enabled = false;
            btnEdit.Enabled = false;

        }


        int row;
        private void Show()
        {

            tbl.Clear();
            // جلب جميع البيانات من جدول Stock_Pull
            tbl = db.readData("select * from Stock_Insert", "");

            if (tbl.Rows.Count <= 0)
            {
                MessageBox.Show("لا يوجد بيانات فى هذه الشاشه");
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

                    txtName.Text = tbl.Rows[row][4].ToString();
                    //Type = Rows{row}[5]
                    txtreason.Text = tbl.Rows[row][6].ToString();
                    txtFrom_To.Text = tbl.Rows[row][7].ToString();
                    TxNumber.Text = tbl.Rows[row][8].ToString();


                }
                catch (Exception ex)
                {
                    // عرض رسالة خطأ إذا حدث مشكلة أثناء عرض البيانات
                    MessageBox.Show("حدث خطأ أثناء عرض البيانات: " + ex.Message, "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    AutoNumber();
                }
            }
            // تفعيل وتعطيل الأزرار بعد عرض البيانات
            btnAdd.Enabled = false;
            btnEdit.Enabled = true;
            btnDelet.Enabled = true;
        }

        private void onLoadScreen()
        {
            fillStock();
            AutoNumber();

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
           // txtName.Clear();
            txtreason.Clear();
            TxNumber.Clear();

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
                btnDelet.Enabled = false;
            } catch (Exception) { }
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
            //if (TxNumber.Text == "" || txtFrom_To.Text == "")
            //{
            //    MessageBox.Show("من فضلك اكمل البيانات");
            //    return;
            //}
            //if (cbxStock.Items.Count >= 1)
            //{
            //    string d = DtpDate.Value.ToString("dd/MM/yyyy");
            //    if (txtName.Text == "") { MessageBox.Show("من فضلك ادخل اسم المودع", "تاكيد"); return; }
            //    if (NudPrice.Value <= 0) { MessageBox.Show("لابد ان يكون مبلغ الايداع اكبر من صفر", "تاكيد"); return; }
            //    db.exceuteData("update Stock set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

            //    db.exceuteData("insert into Stock_Insert (Stock_ID , Money ,Date ,Name ,Type ,Reason ,From_ ,Rec_Num) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' ,N'رصيد اضافى', N'" + txtreason.Text + "',N'" + txtFrom_To.Text + "' ,N'" + TxNumber.Text + "') ", "تم الايداع بنجاح");

            //    onLoadScreen();
            //}
            try
            {
                if (txtFrom_To.Text == "" || txtName.Text == "" || TxNumber.Text == "" || txtreason.Text == "")
                {
                    MessageBox.Show("من فضلك اكمل البيانات");
                    return;
                }
                // تم تحديث صيغة التاريخ لتتوافق مع صيغة التاريخ المعدل Date الجديد في Sql 
                //التعديل بتاريخ 2025-07-17
                string d = DtpDate.Value.ToString("yyyy-MM-dd");

                try
                {
                    db.exceuteData("update stock set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

                    db.exceuteData("insert into Stock_Insert (Stock_ID , Money ,Date ,Name ,Type ,Reason ,From_ ,Rec_Num ) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' ,N'ايداع - رصيد إضافي', N'" + txtreason.Text + "',N'" + txtFrom_To.Text + "' , N'" + TxNumber.Text + "' ) ", "تم صرف المبلغ بنجاح");
                    AutoNumber();
                }
                catch (Exception) { }

            }
            catch (Exception ex)
            {
                // في حال حدوث أي خطأ آخر، سيتم عرضه هنا
                MessageBox.Show("فشلت عملية إضافة السجل.\n\n" + "تفاصيل الخطأ: " + ex.Message,
                                "خطأ فني", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        private void btnFirst_Click(object sender, EventArgs e)
        {
            row = 0;
            Show();
            btnAdd.Enabled = false;
            lblMoney.Text = "-";
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
                lblMoney.Text = "-";
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
                btnAdd.Enabled = false;
                lblMoney.Text = "-";
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
            btnAdd.Enabled = false;
            lblMoney.Text = "-";
        }

        private void btnEdit_Click(object sender, EventArgs e)
        {
            try
            {
                // 1. التحقق من المدخلات
                if (string.IsNullOrWhiteSpace(txtFrom_To.Text) || string.IsNullOrWhiteSpace(txtName.Text) ||
                    string.IsNullOrWhiteSpace(TxNumber.Text) || string.IsNullOrWhiteSpace(txtreason.Text))
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
                // (هذا التحقق قد يحتاج إلى مراجعة دقيقة بناءً على طبيعة العملية،
                // ولكن للحفاظ على المنطق الأصلي، تم الإبقاء عليه مع تعديل بسيط)
                if (NudPrice.Value > (stockMoney + oldMoney))
                {
                    MessageBox.Show("الرصيد في الخزنة غير كافٍ لإتمام هذه العملية بعد التعديل.", "رصيد غير كافٍ", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    return;
                }

                // 4. تنفيذ عمليات التحديث في قاعدة البيانات
                string d = DtpDate.Value.ToString("yyyy-MM-dd"); // استخدام تنسيق تاريخ متوافق مع SQL

                // أولاً: إعادة المبلغ القديم إلى الخزنة
                db.exceuteData("UPDATE Stock SET Money = Money - " + oldMoney + " WHERE Stock_ID = " + cbxStock.SelectedValue, "");

                // ثانياً: إضافة المبلغ الجديد إلى الخزنة (لأنها عملية إيداع)
                db.exceuteData("UPDATE Stock SET Money = Money + " + NudPrice.Value + " WHERE Stock_ID = " + cbxStock.SelectedValue, "");

                // ثالثاً: تحديث بيانات السجل نفسه
                string updateQuery = "UPDATE Stock_Insert SET " +
                      "Stock_ID = " + cbxStock.SelectedValue + ", " +
                      "Money = " + NudPrice.Value + ", " +
                      "Date = N'" + d + "', " +
                      "Name = N'" + txtName.Text.Trim() + "', " +
                      "Reason = N'" + txtreason.Text.Trim() + "', " +
                      "From_ = N'" + txtFrom_To.Text.Trim() + "', " +
                      "Rec_Num = N'" + TxNumber.Text.Trim() + "' " +
                      "WHERE Order_ID = " + txtID.Text;

                db.exceuteData(updateQuery, ""); // تنفيذ الاستعلام بصمت

                // إظهار رسالة النجاح
                MessageBox.Show("تم تعديل البيانات بنجاح.", "نجاح", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // التهيئة لعملية جديدة
                AutoNumber();

            }
            catch (Exception ex)
            {
                MessageBox.Show("حدث خطأ غير متوقع أثناء عملية التعديل.\n\n" + "تفاصيل الخطأ: " + ex.Message,
                                "خطأ فني", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        //كود مسح من جدول الاضافة ومن الخزنة مع تحديث المبلغ
        private void btnDelet_Click(object sender, EventArgs e)
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

        private void btnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }
    }
}