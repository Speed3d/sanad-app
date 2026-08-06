using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Linq;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using System.Threading;
using System.Data.SqlClient;
using System.IO;

namespace Sales_Managment
{
    public partial class Frm_Login : DevExpress.XtraEditors.XtraForm
    {
        Thread t;
        public Frm_Login()
        {
            InitializeComponent();
            try
            {
                t = new Thread(new ThreadStart(StartSplash));
                t.Start();
                Thread.Sleep(5000);
                t.Abort();
            }
            catch (Exception) { }


        }


        private void StartSplash()
        {
            try
            {
                Application.Run(new Splash());
            }
            catch (Exception) { }
        }



        Database db = new Database();
        DataTable tbl = new DataTable();

        // تجييك قاعدة البيانات
        private bool checkDatabase()
        {
            //الاتصال بقاعدة البيانات الخاصة بي
           // SqlConnection conn = new SqlConnection(@"Data Source =DESKTOP-56B5KGI; Initial Catalog = Sales_System; Integrated Security = True");

            //الاتصال بقاعدة البيانات الخاصة بي في الشركة
            SqlConnection conn = new SqlConnection(@"Data Source =DESKTOP-160PK05; Initial Catalog = Sales_System; Integrated Security = True");
            SqlCommand cmd = new SqlCommand("", conn);

            SqlDataReader rdr;

            try
            {
                cmd.CommandText = "exec sys.sp_databases";
                conn.Open();

                rdr = cmd.ExecuteReader();

                while (rdr.Read())
                {
                    if (rdr.GetString(0) == "Sales_System")
                    {
                        return true;
                        break;
                    }
                }
            }
            catch (Exception)
            {
                return false;
            }
            conn.Close();
            rdr.Dispose();
            cmd.Dispose();
            return false;
        }

        //انشاء قاعدة بيانات
        private void cresteDatabase()
        {
            bool check = checkDatabase();

            if (check == false)
            {
                try
                {
                    var fileContent = File.ReadAllText(Application.StartupPath + @"\sqlscript.sql");
                    var sqlqueries = fileContent.Split(new[] { "GO" }, StringSplitOptions.RemoveEmptyEntries);

                    //الاتصال بقاعدة البيانات الخاصة بي

                   // var con = new SqlConnection(@"Data Source=DESKTOP-56B5KGI;Initial Catalog=Sales_System;Integrated Security=True");

                    //الاتصال بقاعدة البيانات الخاصة بي في الشركة

                    var con = new SqlConnection(@"Data Source=DESKTOP-160PK05;Initial Catalog=Sales_System;Integrated Security=True");

                    var cmd = new SqlCommand("query", con);
                    con.Open();

                    foreach (var query in sqlqueries)
                    {
                        cmd.CommandText = query;
                        cmd.ExecuteNonQuery();
                    }
                    con.Close();
                }
                catch (Exception ex) { MessageBox.Show(ex.Message); }
            }
        }

        private void Frm_Login_Load(object sender, EventArgs e)
        {
            try
            {

                cresteDatabase();
            }
            catch (Exception) { }

            txtUserName.Clear();
            txtUserName.Focus();
        }

        private void txtUserName_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == 13)
            {

                txtPassword.Focus();
            }
        }

        private void txtPassword_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == 13)
            {

                btnLogin_Click(null, null);
            }
        }

        private void btnLogin_Click(object sender, EventArgs e)
        {
            tbl.Clear();
            if (rbtnManager.Checked == true)
                tbl = db.readData("select * from Users where User_Name=N'" + txtUserName.Text + "' and User_Password=N'" + txtPassword.Text + "' and Type=N'مدير'", "");
            else if (rbtnEmp.Checked == true)
                tbl = db.readData("select * from Users where User_Name=N'" + txtUserName.Text + "' and User_Password=N'" + txtPassword.Text + "' and Type=N'مستخدم عادى'", "");
            if (tbl.Rows.Count <= 0)
            {
                DataTable tblStock = new DataTable();
                tblStock = db.readData("select * from Stock_Data", "");
                if (tblStock.Rows.Count <= 0)
                {
                    db.exceuteData("insert into Stock_Data Values (1,N'الخزنة الرئيسية') ", "");
                }
                string type = "مدير";
                db.exceuteData("insert into Users values (1 ,N'" + Properties.Settings.Default.USERNAME + "' ,N'" + Properties.Settings.Default.USERNAME + "',N'" + type + "',1,0)", "");
                db.exceuteData("insert into User_Setting Values (1 , 1,1,1,1,1,1,1,1,1,1,1,1)", "");
                db.exceuteData("insert into User_Customer Values (1 , 1,1,1)", "");
                db.exceuteData("insert into User_Supplier Values (1 , 1,1,1)", "");
                db.exceuteData("insert into User_Buy Values (1 , 1,1)", "");
                db.exceuteData("insert into User_Sale Values (1 , 1,1,1)", "");
                db.exceuteData("insert into User_Return Values (1 , 1,1)", "");
                db.exceuteData("insert into User_StockBank Values (1 , 1,1,1,1,1,1,1,1,1)", "");
                db.exceuteData("insert into User_Emp Values (1 , 1,1,1,1,1,1,1)", "");
                db.exceuteData("insert into User_Deserved Values (1 , 1,1,1,1,1,1,1)", "");
                db.exceuteData("insert into User_Report Values (1 , 1,1,1,1,1,1)", "");
                db.exceuteData("insert into User_BackUp Values (1 , 1,1)", "");
                tbl.Clear();
                if (rbtnManager.Checked == true)
                    tbl = db.readData("select * from Users where User_Name=N'" + txtUserName.Text + "' and User_Password=N'" + txtPassword.Text + "' and Type=N'مدير'", "");
                else if (rbtnEmp.Checked == true)
                    tbl = db.readData("select * from Users where User_Name=N'" + txtUserName.Text + "' and User_Password=N'" + txtPassword.Text + "' and Type=N'مستخدم عادى'", "");

            }
            if (tbl.Rows.Count >= 1)
            {
                Properties.Settings.Default.USERNAME = txtUserName.Text;
                Properties.Settings.Default.Stock_ID = Convert.ToInt32(tbl.Rows[0][4]);
                Properties.Settings.Default.Save();
                this.Hide();
                Form1 frm = new Form1();
                frm.ShowDialog();
            }
            else
            {
                MessageBox.Show("كلمة السر او اسم المستخدم  خطا", "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
        }

        private void btnExit_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void pictureBox1_Click(object sender, EventArgs e)
        {

        }
    }
}
