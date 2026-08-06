using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using DevExpress.XtraEditors;

namespace Sales_Managment
{
    public partial class Frm_SanadKabd_Personal : DevExpress.XtraEditors.XtraForm
    {
        public Frm_SanadKabd_Personal()
        {
            InitializeComponent();
        }

        Database db = new Database();
        DataTable tbl = new DataTable();

        private void AutoNumber()
        {
            tbl.Clear();
            tbl = db.readData("select max (Order_ID) from Stock_Insert_Personal", "");

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
            txtFrom.Clear();
            TxNumber.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelete.Enabled = false;
            btnDeleteAll.Enabled = false;
        }

        //تحميل خانة الخزنات
        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data_Personal", "");
            cbxStock.DisplayMember = "Stock_Name";
            cbxStock.ValueMember = "Stock_ID";
        }

        // تحميل خانة الشركاء
        private void fillPersonalTybe()
        {
            cbxAddType.DataSource = db.readData("select * from Add_Personal", "");
            cbxAddType.DisplayMember = "Personal_Name";
            cbxAddType.ValueMember = "Personal_ID";
        }


        int row;

        //دالة شو لاستخدامها في الازرار لتحميل البيانات
        private void Show()
        {
            tbl.Clear();
            tbl = db.readData("select * from Stock_Insert_Personal", "");

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
                    this.Text = tbl.Rows[row][3].ToString();
                    DateTime dt = DateTime.ParseExact(this.Text, "dd/MM/yyyy", null);
                    DtpDate.Value = dt;
                    txtName.Text = tbl.Rows[row][4].ToString();
                    txtFrom.Text = tbl.Rows[row][5].ToString();
                    txtReason.Text = tbl.Rows[row][6].ToString();
                    TxNumber.Text = tbl.Rows[row][8].ToString();


                }
                catch (Exception) { }
            }

            btnAdd.Enabled = false;
            btnNew.Enabled = true;
            btnDelete.Enabled = true;
            btnDeleteAll.Enabled = true;
        }

        string stock_ID = "";


        private void Frm_SanadKabd_Personal_Load(object sender, EventArgs e)
        {
            AutoNumber();
            stock_ID = Convert.ToString(Properties.Settings.Default.Stock_ID);
            fillStock();
            fillPersonalTybe();
            btnDeleteAll.Enabled = false;
        }


        private void BtnAdd_Click(object sender, EventArgs e)
        {
            if (txtFrom.Text == "" || txtName.Text == "" || TxNumber.Text == "" || txtReason.Text == "")
            {
                MessageBox.Show("من فضلك اكمل البيانات");
                return;
            }
            string d = DtpDate.Value.ToString("dd/MM/yyyy");
            db.exceuteData("update Stock_P set Money=Money + " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");

            db.exceuteData("insert into Stock_Insert_Personal (Stock_ID , Money ,Date ,Name ,Reason ,Item_Personal ,Rec_Num ,From_) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' , N'" + txtReason.Text + "'," + cbxAddType.SelectedValue + " ,N'" + TxNumber.Text + "' , N'" + txtFrom.Text + "') ", "تم الادخال منبلغ القبض بنجاح");

            //Print();
            AutoNumber();
        }


        private void BtnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }


        private void BtnDelete_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("هل انتا متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                db.readData("delete from Stock_Insert_Personal  where Order_ID=" + txtID.Text + "", "تم مسح البيانات بنجاح");
                db.exceuteData("update Stock_P set Money=Money - " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");
                AutoNumber();
            }
        }


        private void BtnFirst_Click(object sender, EventArgs e)
        {
            row = 0;
            Show();
        }


        private void BtnPrev_Click(object sender, EventArgs e)
        {
            if (row == 0)
            {
                tbl.Clear();
                tbl = db.readData("select count(Order_ID) from Stock_Insert_Personal", "");
                row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
                Show();
            }
            else
            {


                row--;
                Show();
            }
        }


        private void BtnNext_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Order_ID) from Stock_Insert_Personal", "");
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


        private void BtnLast_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            tbl = db.readData("select count(Order_ID) from Stock_Insert_Personal", "");
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
            Show();
        }
    }
}