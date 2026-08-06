using System;
using System.Data;
using System.Linq;
using System.Windows.Forms;

namespace Sales_Managment
{
    public partial class Frm_AddType : DevExpress.XtraEditors.XtraForm
    {
        public Frm_AddType()
        {
            InitializeComponent();
        }
        Database db = new Database();
        DataTable tbl = new DataTable();

        private void AutoNumber()
        {
            tbl.Clear();
            tbl = db.readData("select max (Type_ID) from Add_Type", string.Empty);

            if ((tbl.Rows[0][0].ToString() == DBNull.Value.ToString()))
            {

                txtID.Text = "1";
            }
            else
            {

                txtID.Text = (Convert.ToInt32(tbl.Rows[0][0]) + 1).ToString();
            }

            txtName.Clear();
            btnAdd.Enabled = true;
            btnNew.Enabled = true;
            btnDelete.Enabled = false;
            bakup.Visible = false ;
        }

        int row;

        private void Show()
        {
            tbl.Clear();
            tbl = db.readData("select * from Add_Type", string.Empty);

            if (tbl.Rows.Count <= 0)
            {
                MessageBox.Show("لا يوجد بيانات فى الشاشة");
            }
            else
            {
                txtID.Text = tbl.Rows[row][0].ToString();
                txtName.Text = tbl.Rows[row][1].ToString();
            }

            btnAdd.Enabled = false;
            btnNew.Enabled = true;
            btnDelete.Enabled = true;
        }

        private void Frm_AddType_Load(object sender, EventArgs e)
        {
            AutoNumber();
        }


        private void btnAdd_Click(object sender, EventArgs e)
        {
            if (txtName.Text == string.Empty)
            {
                MessageBox.Show("من فضلك ادخل اسم الصنف");
                return;
            }
            db.exceuteData("insert into Add_Type Values (" + txtID.Text + " ,N'" + txtName.Text + "')", "تم الادخال بنجاح");

            AutoNumber();
        }

        private void btnNew_Click(object sender, EventArgs e)
        {
            AutoNumber();
        }

        private void btnDelete_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("هل انتا متاكد من مسح البيانات", "تاكيد", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
            {
                db.readData("delete from Add_Type where Type_ID=" + txtID.Text + string.Empty, "تم مسح البيانات بنجاح");
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
                tbl = db.readData("select count(Type_ID) from Add_Type", string.Empty);
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
            tbl = db.readData("select count(Type_ID) from Add_Type", string.Empty);
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
            tbl = db.readData("select count(Type_ID) from Add_Type", string.Empty);
            row = Convert.ToInt32(tbl.Rows[0][0]) - 1;
            Show();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            //tesst frm = new tesst();
            //frm.ShowDialog();
            //sim_Button1.Text = "حجزت";
            //sim_Button1.Enabled = false;
            //bakup.Visible = true ;
        }

        private void bakup_Click(object sender, EventArgs e)
        {
            sim_Button1.Enabled = true;
            bakup.Visible = false;

        }
    }
}