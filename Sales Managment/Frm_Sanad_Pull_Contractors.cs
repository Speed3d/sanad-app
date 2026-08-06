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
    public partial class Frm_Sanad_Pull_Contractors : DevExpress.XtraEditors.XtraForm
    {
        public Frm_Sanad_Pull_Contractors()
        {
            InitializeComponent();
        }

        Database db = new Database();
        DataTable tbl = new DataTable();

        private void AutoNumber()
        {
            // tbl.Clear();
            tbl = db.readData("select max (Order_ID) from Stock_Pull_Contractors", "");

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
            //   txtName.Clear();
            // txtTo.Clear();
            TxNumber.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelete.Enabled = false;
            btnDeleteAll.Enabled = false;
        }


        private void fillStock()
        {
            cbxStock.DataSource = db.readData("select * from Stock_Data_Contractors", "");
            cbxStock.DisplayMember = "Stock_Contractors_Name";
            cbxStock.ValueMember = "Stock_Contractors_ID";
        }

        private void fillContractors()
        {
            cbxAddContractors.DataSource = db.readData("select * from Add_Contractors", "");
            cbxAddContractors.DisplayMember = "Contractors_Name";
            cbxAddContractors.ValueMember = "Contractors_ID";
        }


        int row;


        private void Show()
        {
            tbl.Clear();
            txtReason.Clear();
            txtName.Clear();
            txtTo.Clear();
            TxNumber.Clear();
            tbl = db.readData("select * from Stock_Pull_Contractors", "");

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
                    txtReason.Text = tbl.Rows[row][5].ToString();
                    cbxAddContractors.SelectedValue = tbl.Rows[row][6].ToString();
                    TxNumber.Text = tbl.Rows[row][7].ToString();
                    txtTo.Text = tbl.Rows[row][8].ToString();


                }
                catch (Exception) { }
            }

            btnAdd.Enabled = false;
            btnNew.Enabled = true;
            btnDelete.Enabled = true;
            btnDeleteAll.Enabled = false;

        }


        private void Frm_Sanad_Pull_Contractors_Load(object sender, EventArgs e)
        {
            AutoNumber();
            stock_ID = Convert.ToString(Properties.Settings.Default.Stock_ID);
            fillStock();
            fillContractors();
            btnDeleteAll.Enabled = false;
        }


        string stock_ID = "";


        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (txtTo.Text == "" || txtName.Text == "" || TxNumber.Text == "" || txtReason.Text == "")
            {
                MessageBox.Show("من فضلك اكمل البيانات");
                return;
            }
            string d = DtpDate.Value.ToString("dd/MM/yyyy");

            // decimal stock_Money = 0;
            try
            {
                tbl = db.readData("select * from Stock_Contractors where Stock_ID=" + cbxStock.SelectedValue + "", "");
            }
            catch (Exception) { }

            if  //اذا الخزنة لا يوجد بها رصيد
                (NudPrice.Value > Convert.ToDecimal(tbl.Rows[0][1]))
            {
                MessageBox.Show(" لايوجد رصيد كافي فى الخزنة لاجراء العملية");
                return;
            }
            db.exceuteData("update Stock_Contractors set Money=Money - " + NudPrice.Value + " where Stock_ID=" + cbxStock.SelectedValue + "", "");


            db.exceuteData("insert into Stock_Pull_Contractors (Stock_ID , Money ,Date ,Name ,Reason ,Item_Contractors ,Rec_Num ,Too) values (" + cbxStock.SelectedValue + " ," + NudPrice.Value + " ,N'" + d + "' ,N'" + txtName.Text + "' , N'" + txtReason.Text + "'," + cbxAddContractors.SelectedValue + " ,N'" + TxNumber.Text + "' , N'" + txtTo.Text + "') ", "تم صرف المبلغ الى المقاول بنجاح");
            //Print();
            AutoNumber();
        }


        private void btnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }


        private void btnDelete_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("هل انت متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                db.readData("delete from Stock_Pull_Contractors  where Order_ID=" + txtID.Text + "", "تم مسح البيانات بنجاح");
                db.exceuteData("update Stock_Contractors set Money=Money + " + NudPrice.Value + " where Stock_Contractors_ID=" + cbxStock.SelectedValue + "", "");
                AutoNumber();
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
                tbl = db.readData("select count(Order_ID) from Stock_Pull_Contractors", "");
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
            tbl = db.readData("select count(Order_ID) from Stock_Pull_Contractors", "");
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
            tbl = db.readData("select count(Order_ID) from Stock_Pull_Contractors", "");
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
            Show();
        }


    }
}