using System;
using System.Data;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.IO;
using System.Threading.Tasks;
using ExcelDataReader;

namespace Sales_Managment
{
    public partial class Frm_ExcelIMporterTo : DevExpress.XtraEditors.XtraForm
    {
        
        public Frm_ExcelIMporterTo()
        {
            InitializeComponent();

            // تهيئة القيم الافتراضية لمربعات النصوص عند بدء تشغيل التطبيق
            txtExcelFilePath.Text = ""; // اتركها فارغة ليختار المستخدم الملف
            //txtConnectionString.Text = @"Data Source=.\SQLEXPRESS;Initial Catalog=Sales_System;Integrated Security=True";
            // حاسبة الشركة
            txtConnectionString.Text = @"Data Source=DESKTOP-160PK05;Initial Catalog=Sales_System;Integrated Security=True";
            txtStatus.Text = "جاهز للاستيراد." + Environment.NewLine;
        }


        // دالة لعرض الرسائل في مربع النص الخاص بالحالة (txtStatus)
        // تستخدم Invoke لضمان تحديث الواجهة بشكل آمن من أي Thread
        private void LogStatus(string message)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action(() => {
                    txtStatus.AppendText($"{DateTime.Now.ToString("HH:mm:ss")} - {message}{Environment.NewLine}");
                    txtStatus.ScrollToCaret(); // التمرير لأسفل تلقائياً لعرض أحدث رسالة
                }));
            }
            else
            {
                txtStatus.AppendText($"{DateTime.Now.ToString("HH:mm:ss")} - {message}{Environment.NewLine}");
                txtStatus.ScrollToCaret();
            }
        }

        // الدالة الرئيسية لاستيراد البيانات من Excel إلى SQL Server باستخدام ExcelDataReader و SqlBulkCopy
        // تعمل بدون الحاجة لتثبيت Office أو أي Driver إضافي
        private void ImportData(string excelFilePath, string connectionString)
        {
            try
            {
                string fileExtension = Path.GetExtension(excelFilePath);

                if (!fileExtension.Equals(".xls", StringComparison.OrdinalIgnoreCase) &&
                    !fileExtension.Equals(".xlsx", StringComparison.OrdinalIgnoreCase) &&
                    !fileExtension.Equals(".xlsm", StringComparison.OrdinalIgnoreCase))
                {
                    LogStatus("خطأ: امتداد ملف Excel غير مدعوم.");
                    MessageBox.Show("امتداد ملف Excel غير مدعوم. الرجاء اختيار ملف .xls أو .xlsx أو .xlsm", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                DataTable excelData = new DataTable();

                // قراءة ملف Excel باستخدام ExcelDataReader (لا يحتاج Office مثبتاً)
                using (var stream = File.Open(excelFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    using (IExcelDataReader reader = ExcelReaderFactory.CreateReader(stream))
                    {
                        DataSet dataSet = reader.AsDataSet(new ExcelDataSetConfiguration
                        {
                            ConfigureDataTable = _ => new ExcelDataTableConfiguration { UseHeaderRow = true }
                        });

                        if (dataSet.Tables.Count == 0)
                        {
                            LogStatus("خطأ: لم يتم العثور على أوراق عمل في ملف Excel.");
                            return;
                        }

                        excelData = dataSet.Tables[0];
                        LogStatus($"تم قراءة {excelData.Rows.Count} صفًا من ورقة العمل: {excelData.TableName}");

                        if (excelData.Columns.Count > 0)
                        {
                            string columnNames = "أسماء الأعمدة التي تم قراءتها من Excel: ";
                            foreach (DataColumn col in excelData.Columns)
                                columnNames += $"'{col.ColumnName}' ";
                            LogStatus(columnNames);
                        }
                        else
                        {
                            LogStatus("تحذير: لم يتم قراءة أي أعمدة من ملف Excel.");
                        }
                    }
                }

                // **************************************************************************
                // تحديد أسماء الأعمدة في ملف Excel
                // **هام جداً:** قم بتعديل هذه المتغيرات لتطابق الأسماء الدقيقة لرؤوس الأعمدة
                // في الصف الأول من ملف Excel الخاص بك.
                // استخدم مخرجات "أسماء الأعمدة التي تم قراءتها من Excel" في مربع الحالة للمساعدة.
                // **************************************************************************
                string excelOrderIdColumnName = "Order_ID";
                string excelStockIdColumnName = "Stock_ID";
                string excelMoneyColumnName = "Money";
                string excelDateColumnName = "Date"; // تم تحديثها لتكون "Date" كما في طلبك الأخير
                string excelNameColumnName = "Name"; // تم تحديثها لتكون "Name" كما في طلبك الأخير
                string excelTypeColumnName = "Type";
                string excelReasonColumnName = "Reason";
                string excelTooColumnName = "From_"; // حافظ على الشرطة السفلية إذا كانت جزءاً من الاسم الفعلي
                string excelRecNumColumnName = "Rec_Num";
                // **************************************************************************

                // معالجة عمود التاريخ للحصول على التاريخ فقط (00:00:00)
                if (excelData.Columns.Contains(excelDateColumnName))
                {
                    // تعريف تنسيقات التاريخ المتوقعة التي قد تأتي من Excel
                    string[] dateFormats =
                        {
                          "dd-MM-yyyy HH:mm:ss", // التنسيق الذي ظهر في رسالة الخطأ (مثال: 21-10-2021 12:00:00)
                          "dd/MM/yyyy HH:mm:ss", // تنسيق شائع آخر
                          "yyyy-MM-dd HH:mm:ss", // تنسيق ISO
                          "M/d/yyyy h:mm:ss tt", // تنسيق أمريكي مع AM/PM
                          "dd-MM-yyyy",          // تنسيق تاريخ فقط
                          "dd/MM/yyyy",          // تنسيق تاريخ فقط
                          "yyyy-MM-dd"           // تنسيق تاريخ فقط
                        };

                    foreach (DataRow row in excelData.Rows)
                    {
                        object cellValue = row[excelDateColumnName];
                        DateTime parsedDate;

                        if (cellValue == DBNull.Value || cellValue == null)
                        {
                            row[excelDateColumnName] = DBNull.Value; // إذا كانت القيمة فارغة أو NULL
                        }
                        else if (cellValue is DateTime dt)
                        {
                            row[excelDateColumnName] = dt.Date; // إذا كانت القيمة بالفعل DateTime، خذ التاريخ فقط
                        }
                        else if (cellValue is double dbl)
                        {
                            // إذا تم تخزين التاريخ كرقم تسلسلي (التنسيق الافتراضي لـ Excel)
                            try
                            {
                                row[excelDateColumnName] = DateTime.FromOADate(dbl).Date;
                            }
                            catch (ArgumentException)
                            {
                                // التعامل مع الحالات التي قد لا يكون فيها الرقم صالحًا كتاريخ OADate
                                LogStatus($"تحذير: قيمة رقمية غير صالحة كـ OADate في عمود التاريخ. القيمة: '{dbl}'. سيتم تعيينها إلى NULL.");
                                row[excelDateColumnName] = DBNull.Value;
                            }
                        }
                        // محاولة تحليل القيمة كنص باستخدام التنسيقات المحددة
                        else if (DateTime.TryParseExact(cellValue.ToString(), dateFormats, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out parsedDate))
                        {
                            row[excelDateColumnName] = parsedDate.Date; // تم التحويل بنجاح من نص
                        }
                        else
                        {
                            // إذا فشلت جميع محاولات التحويل، سجل تحذيرًا وعيّن القيمة إلى NULL
                            LogStatus($"تحذير: قيمة تاريخ غير صالحة في الصف. القيمة: '{cellValue}'. سيتم تعيينها إلى NULL.");
                            row[excelDateColumnName] = DBNull.Value;
                        }
                    }
                    LogStatus("تم معالجة عمود التاريخ للحصول على التاريخ فقط.");
                }
                else
                {
                    LogStatus($"تحذير: عمود '{excelDateColumnName}' لم يتم العثور عليه في ملف Excel. تأكد من تطابق اسم العمود.");
                }



                // استخدام SqlBulkCopy لإدراج البيانات بكفاءة في SQL Server
                using (SqlConnection sqlConnection = new SqlConnection(connectionString))
                {
                    sqlConnection.Open();
                    LogStatus("تم الاتصال بقاعدة بيانات SQL بنجاح.");

                    using (SqlBulkCopy bulkCopy = new SqlBulkCopy(sqlConnection))
                    {
                        // **تأكد من مطابقة اسم الجدول الهدف في SQL Server**
                        bulkCopy.DestinationTableName = "Stock_Insert";

                        // **************************************************************************
                        // تعيين ربط الأعمدة بين DataTable (الذي تم قراءته من Excel) وجدول SQL Server
                        // **الوسيط الأول في Add() هو اسم العمود في DataTable (الذي يجب أن يطابق رأس عمود Excel).**
                        // **الوسيط الثاني في Add() هو اسم العمود في جدول SQL Server.**
                        // **************************************************************************

                        // ربط الأعمدة الموجودة
                        bulkCopy.ColumnMappings.Add(excelDateColumnName, "Date"); // اسم عمود Excel -> اسم عمود SQL
                        bulkCopy.ColumnMappings.Add(excelNameColumnName, "Name");   // اسم عمود Excel -> اسم عمود SQL
                        bulkCopy.ColumnMappings.Add(excelOrderIdColumnName, "Order_ID");
                        bulkCopy.ColumnMappings.Add(excelStockIdColumnName, "Stock_ID");
                        bulkCopy.ColumnMappings.Add(excelMoneyColumnName, "Money");
                        bulkCopy.ColumnMappings.Add(excelTypeColumnName, "Type");
                        bulkCopy.ColumnMappings.Add(excelReasonColumnName, "Reason");
                        bulkCopy.ColumnMappings.Add(excelTooColumnName, "From_");
                        bulkCopy.ColumnMappings.Add(excelRecNumColumnName, "Rec_Num");
                        // **************************************************************************


                        LogStatus("بدء إدراج البيانات باستخدام SqlBulkCopy...");
                        bulkCopy.WriteToServer(excelData); // كتابة البيانات إلى SQL Server
                        LogStatus("تم الانتهاء من إدراج جميع البيانات في SQL.");
                    }
                }
                // إضافة رسالة النجاح هنا
                MessageBox.Show("تم استيراد البيانات بنجاح!", "نجاح", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (FileNotFoundException)
            {
                LogStatus("خطأ: ملف Excel غير موجود في المسار المحدد.");
                MessageBox.Show("ملف Excel غير موجود في المسار المحدد.", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch (SqlException sqlEx)
            {
                LogStatus($"خطأ في قاعدة البيانات: {sqlEx.Message}");
                MessageBox.Show($"خطأ في قاعدة البيانات: {sqlEx.Message}", "خطأ في SQL", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch (Exception ex)
            {
                LogStatus($"حدث خطأ غير متوقع: {ex.Message}");
                MessageBox.Show($"حدث خطأ غير متوقع: {ex.Message}", "خطأ عام", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }


        // حدث النقر على زر "استعراض..." لاختيار ملف Excel
        private void btnBrowse_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFileDialog = new OpenFileDialog();
            // تحديد أنواع الملفات المسموح بها (Excel 97-2003 و Excel 2007+)
            openFileDialog.Filter = "Excel Files|*.xls;*.xlsx;*.xlsm|All Files|*.*";
            openFileDialog.Title = "اختر ملف Excel للاستيراد";

            if (openFileDialog.ShowDialog() == DialogResult.OK)
            {
                txtExcelFilePath.Text = openFileDialog.FileName; // وضع المسار المختار في مربع النص
                LogStatus($"تم اختيار الملف: {txtExcelFilePath.Text}");
            }
        }


        // حدث النقر على زر "بدء الاستيراد" لبدء عملية الاستيراد
        private async void btnImport_Click(object sender, EventArgs e)
        {
            string excelFilePath = txtExcelFilePath.Text;
            string connectionString = txtConnectionString.Text;

            // التحقق من صحة مسار ملف Excel
            if (string.IsNullOrWhiteSpace(excelFilePath) || !File.Exists(excelFilePath))
            {
                LogStatus("الرجاء تحديد مسار ملف Excel صالح.");
                MessageBox.Show("الرجاء تحديد مسار ملف Excel صالح.", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // التحقق من صحة سلسلة الاتصال
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                LogStatus("الرجاء إدخال سلسلة اتصال قاعدة البيانات.");
                MessageBox.Show("الرجاء إدخال سلسلة اتصال قاعدة البيانات.", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // تعطيل الأزرار أثناء عملية الاستيراد لمنع النقرات المتعددة وتجميد الواجهة
            btnBrowse.Enabled = false;
            btnImport.Enabled = false;
            LogStatus("بدء عملية الاستيراد...");

            // تنفيذ عملية الاستيراد في Thread منفصل (خلفية)
            // هذا يمنع الواجهة من التوقف عن الاستجابة (freezing) أثناء معالجة الملفات الكبيرة
            await Task.Run(() => ImportData(excelFilePath, connectionString));

            // إعادة تمكين الأزرار بعد الانتهاء من العملية
            btnBrowse.Enabled = true;
            btnImport.Enabled = true;
            LogStatus("اكتملت عملية الاستيراد.");
        }
    }
}