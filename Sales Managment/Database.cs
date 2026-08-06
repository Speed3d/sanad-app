using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data.SqlClient;
using System.Data;
using System.Windows.Forms;
namespace Sales_Managment
{
    class Database
    {
        //الاتصال بقاعدة البيانات

        //اسم حاسبة البيت
        // SqlConnection conn = new SqlConnection(@"Data Source=DESKTOP-EN9QU19;Initial Catalog=Sales_System;Integrated Security=True");

         //SqlConnection conn = new SqlConnection(@"Data Source=.\SQLEXPRESS;Initial Catalog=Sales_System;Integrated Security=True");


        // حاسبة الشركة
        SqlConnection conn = new SqlConnection(@"Data Source=DESKTOP-160PK05;Initial Catalog=Sales_System;Integrated Security=True");


        SqlCommand cmd = new SqlCommand();
        
        // select دالة ال 
        public DataTable readData(string stmt ,string message)
        {
            DataTable tbl = new DataTable();
            try
            {
                cmd.Connection = conn;
                cmd.CommandText = stmt;
                conn.Open();
                //تحميل قاعدة البيانات الى جدول tb1
                tbl.Load(cmd.ExecuteReader());

                conn.Close();
                if (message != "")
                {
                    MessageBox.Show(message, "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {

                MessageBox.Show(ex.Message);
            } finally
            {
                conn.Close();
            }
         
            
            return tbl;
        }

        // insert update delete دالة 
        public bool exceuteData(string stmt ,string message)
        {
            try
            {
                cmd.Connection = conn;
                cmd.CommandText = stmt;
                conn.Open();
                cmd.ExecuteNonQuery();
                conn.Close();
                if(message !="")
                {
                    MessageBox.Show(message, "تاكيد", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                return true;
            }catch(Exception ex)
            {
                return false;
            }
            finally
            {
                conn.Close();
            }

        }

    }
}
