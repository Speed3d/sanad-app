namespace Sales_Managment
{
    partial class Frm_Sanad_Pull_Perso_Report
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Frm_Sanad_Pull_Perso_Report));
            this.rbtnAllStock = new System.Windows.Forms.RadioButton();
            this.rbtnOneStock = new System.Windows.Forms.RadioButton();
            this.label10 = new System.Windows.Forms.Label();
            this.cbxStock = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.txtTotal = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.DgvSearch = new System.Windows.Forms.DataGridView();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.btnSearchPersonal = new DevExpress.XtraEditors.SimpleButton();
            this.txtSearch = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.DtpTo = new System.Windows.Forms.DateTimePicker();
            this.DtpFrom = new System.Windows.Forms.DateTimePicker();
            this.btnSearchNumber = new DevExpress.XtraEditors.SimpleButton();
            this.btnPrintPersonal = new DevExpress.XtraEditors.SimpleButton();
            this.btnPrintAll = new DevExpress.XtraEditors.SimpleButton();
            this.btnPtintNumber = new DevExpress.XtraEditors.SimpleButton();
            this.btnDelete = new DevExpress.XtraEditors.SimpleButton();
            this.texInsert_Personal = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.cbxAddType = new System.Windows.Forms.ComboBox();
            this.Text_Total_Insert = new System.Windows.Forms.TextBox();
            ((System.ComponentModel.ISupportInitialize)(this.DgvSearch)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // rbtnAllStock
            // 
            this.rbtnAllStock.AutoSize = true;
            this.rbtnAllStock.Checked = true;
            this.rbtnAllStock.ForeColor = System.Drawing.Color.Blue;
            this.rbtnAllStock.Location = new System.Drawing.Point(90, 29);
            this.rbtnAllStock.Name = "rbtnAllStock";
            this.rbtnAllStock.Size = new System.Drawing.Size(87, 20);
            this.rbtnAllStock.TabIndex = 66;
            this.rbtnAllStock.TabStop = true;
            this.rbtnAllStock.Text = "كل السـنـوات";
            this.rbtnAllStock.UseVisualStyleBackColor = true;
            // 
            // rbtnOneStock
            // 
            this.rbtnOneStock.AutoSize = true;
            this.rbtnOneStock.ForeColor = System.Drawing.Color.Blue;
            this.rbtnOneStock.Location = new System.Drawing.Point(90, 64);
            this.rbtnOneStock.Name = "rbtnOneStock";
            this.rbtnOneStock.Size = new System.Drawing.Size(89, 20);
            this.rbtnOneStock.TabIndex = 65;
            this.rbtnOneStock.Text = "سـنـة المحددة";
            this.rbtnOneStock.UseVisualStyleBackColor = true;
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label10.ForeColor = System.Drawing.Color.Red;
            this.label10.Location = new System.Drawing.Point(14, 48);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(70, 18);
            this.label10.TabIndex = 64;
            this.label10.Text = "اختر الـسـنـة";
            // 
            // cbxStock
            // 
            this.cbxStock.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.SuggestAppend;
            this.cbxStock.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cbxStock.FormattingEnabled = true;
            this.cbxStock.Location = new System.Drawing.Point(14, 101);
            this.cbxStock.Name = "cbxStock";
            this.cbxStock.Size = new System.Drawing.Size(193, 24);
            this.cbxStock.TabIndex = 63;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.ForeColor = System.Drawing.Color.Red;
            this.label3.Location = new System.Drawing.Point(688, 483);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(216, 16);
            this.label3.TabIndex = 58;
            this.label3.Text = "اجمالي مبلغ السندات الصرف للفترة المحددة :";
            // 
            // txtTotal
            // 
            this.txtTotal.Location = new System.Drawing.Point(720, 452);
            this.txtTotal.Name = "txtTotal";
            this.txtTotal.ReadOnly = true;
            this.txtTotal.Size = new System.Drawing.Size(149, 22);
            this.txtTotal.TabIndex = 61;
            this.txtTotal.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 18F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.ForeColor = System.Drawing.Color.Red;
            this.label2.Location = new System.Drawing.Point(305, 7);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(246, 29);
            this.label2.TabIndex = 59;
            this.label2.Text = "شاشة تقارير سحب الشركاء";
            // 
            // DgvSearch
            // 
            this.DgvSearch.AllowUserToAddRows = false;
            this.DgvSearch.AllowUserToDeleteRows = false;
            this.DgvSearch.AllowUserToOrderColumns = true;
            this.DgvSearch.AllowUserToResizeColumns = false;
            this.DgvSearch.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.AllCells;
            this.DgvSearch.AutoSizeRowsMode = System.Windows.Forms.DataGridViewAutoSizeRowsMode.AllCells;
            this.DgvSearch.BackgroundColor = System.Drawing.Color.White;
            this.DgvSearch.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridViewCellStyle1.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle1.BackColor = System.Drawing.Color.Beige;
            dataGridViewCellStyle1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle1.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(40)))), ((int)(((byte)(40)))), ((int)(((byte)(40)))));
            dataGridViewCellStyle1.SelectionBackColor = System.Drawing.Color.Yellow;
            dataGridViewCellStyle1.SelectionForeColor = System.Drawing.Color.Blue;
            dataGridViewCellStyle1.WrapMode = System.Windows.Forms.DataGridViewTriState.False;
            this.DgvSearch.DefaultCellStyle = dataGridViewCellStyle1;
            this.DgvSearch.Location = new System.Drawing.Point(17, 148);
            this.DgvSearch.Name = "DgvSearch";
            this.DgvSearch.ReadOnly = true;
            this.DgvSearch.RightToLeft = System.Windows.Forms.RightToLeft.Yes;
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle2.BackColor = System.Drawing.Color.White;
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle2.ForeColor = System.Drawing.SystemColors.WindowText;
            dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle2.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.DgvSearch.RowHeadersDefaultCellStyle = dataGridViewCellStyle2;
            this.DgvSearch.RowTemplate.DefaultCellStyle.BackColor = System.Drawing.Color.White;
            this.DgvSearch.RowTemplate.DefaultCellStyle.ForeColor = System.Drawing.Color.Blue;
            this.DgvSearch.RowTemplate.DefaultCellStyle.SelectionBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(255)))), ((int)(((byte)(255)))), ((int)(((byte)(128)))));
            this.DgvSearch.RowTemplate.DefaultCellStyle.SelectionForeColor = System.Drawing.Color.Blue;
            this.DgvSearch.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.DgvSearch.Size = new System.Drawing.Size(887, 293);
            this.DgvSearch.TabIndex = 60;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.btnSearchPersonal);
            this.groupBox1.Controls.Add(this.txtSearch);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.label4);
            this.groupBox1.Controls.Add(this.label6);
            this.groupBox1.Controls.Add(this.DtpTo);
            this.groupBox1.Controls.Add(this.DtpFrom);
            this.groupBox1.Controls.Add(this.btnSearchNumber);
            this.groupBox1.Location = new System.Drawing.Point(213, 38);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(698, 105);
            this.groupBox1.TabIndex = 57;
            this.groupBox1.TabStop = false;
            // 
            // btnSearchPersonal
            // 
            this.btnSearchPersonal.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearchPersonal.Appearance.Options.UseFont = true;
            this.btnSearchPersonal.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearchPersonal.ImageOptions.Image")));
            this.btnSearchPersonal.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearchPersonal.Location = new System.Drawing.Point(7, 14);
            this.btnSearchPersonal.Name = "btnSearchPersonal";
            this.btnSearchPersonal.Size = new System.Drawing.Size(146, 39);
            this.btnSearchPersonal.TabIndex = 58;
            this.btnSearchPersonal.Text = "البحث اسم شريك";
            this.btnSearchPersonal.Click += new System.EventHandler(this.btnSearchPersonal_Click);
            // 
            // txtSearch
            // 
            this.txtSearch.Location = new System.Drawing.Point(170, 63);
            this.txtSearch.Multiline = true;
            this.txtSearch.Name = "txtSearch";
            this.txtSearch.Size = new System.Drawing.Size(277, 29);
            this.txtSearch.TabIndex = 57;
            this.txtSearch.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.ForeColor = System.Drawing.Color.Red;
            this.label1.Location = new System.Drawing.Point(613, 69);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(42, 16);
            this.label1.TabIndex = 10;
            this.label1.Text = "الــــى :";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.ForeColor = System.Drawing.Color.Red;
            this.label4.Location = new System.Drawing.Point(614, 24);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(42, 16);
            this.label4.TabIndex = 9;
            this.label4.Text = "مـــــن :";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.ForeColor = System.Drawing.Color.Red;
            this.label6.Location = new System.Drawing.Point(201, 25);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(249, 17);
            this.label6.TabIndex = 56;
            this.label6.Text = "اكتب الاسم او جزء من الاسم الذي تريد البحث عنه : ";
            // 
            // DtpTo
            // 
            this.DtpTo.Format = System.Windows.Forms.DateTimePickerFormat.Short;
            this.DtpTo.Location = new System.Drawing.Point(478, 61);
            this.DtpTo.Name = "DtpTo";
            this.DtpTo.Size = new System.Drawing.Size(129, 22);
            this.DtpTo.TabIndex = 8;
            // 
            // DtpFrom
            // 
            this.DtpFrom.Format = System.Windows.Forms.DateTimePickerFormat.Short;
            this.DtpFrom.Location = new System.Drawing.Point(478, 20);
            this.DtpFrom.Name = "DtpFrom";
            this.DtpFrom.Size = new System.Drawing.Size(129, 22);
            this.DtpFrom.TabIndex = 7;
            // 
            // btnSearchNumber
            // 
            this.btnSearchNumber.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearchNumber.Appearance.Options.UseFont = true;
            this.btnSearchNumber.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearchNumber.ImageOptions.Image")));
            this.btnSearchNumber.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearchNumber.Location = new System.Drawing.Point(7, 59);
            this.btnSearchNumber.Name = "btnSearchNumber";
            this.btnSearchNumber.Size = new System.Drawing.Size(146, 34);
            this.btnSearchNumber.TabIndex = 40;
            this.btnSearchNumber.Text = "البـحـث رقم وصل";
            this.btnSearchNumber.Click += new System.EventHandler(this.btnSearchNumber_Click);
            // 
            // btnPrintPersonal
            // 
            this.btnPrintPersonal.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintPersonal.Appearance.Options.UseFont = true;
            this.btnPrintPersonal.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintPersonal.ImageOptions.Image")));
            this.btnPrintPersonal.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintPersonal.Location = new System.Drawing.Point(161, 448);
            this.btnPrintPersonal.Name = "btnPrintPersonal";
            this.btnPrintPersonal.Size = new System.Drawing.Size(151, 51);
            this.btnPrintPersonal.TabIndex = 69;
            this.btnPrintPersonal.Text = "طباعة خزنة محددة\r\nواسم شريك محدد";
            this.btnPrintPersonal.Click += new System.EventHandler(this.btnPrintPersonal_Click);
            // 
            // btnPrintAll
            // 
            this.btnPrintAll.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintAll.Appearance.Options.UseFont = true;
            this.btnPrintAll.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintAll.ImageOptions.Image")));
            this.btnPrintAll.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintAll.Location = new System.Drawing.Point(17, 448);
            this.btnPrintAll.Name = "btnPrintAll";
            this.btnPrintAll.Size = new System.Drawing.Size(127, 51);
            this.btnPrintAll.TabIndex = 68;
            this.btnPrintAll.Text = "طباعة الكل";
            this.btnPrintAll.Click += new System.EventHandler(this.btnPrintAll_Click);
            // 
            // btnPtintNumber
            // 
            this.btnPtintNumber.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPtintNumber.Appearance.Options.UseFont = true;
            this.btnPtintNumber.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPtintNumber.ImageOptions.Image")));
            this.btnPtintNumber.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPtintNumber.Location = new System.Drawing.Point(330, 448);
            this.btnPtintNumber.Name = "btnPtintNumber";
            this.btnPtintNumber.Size = new System.Drawing.Size(151, 51);
            this.btnPtintNumber.TabIndex = 67;
            this.btnPtintNumber.Text = "طباعة خزنة محددة\r\nورقم وصل محددة";
            this.btnPtintNumber.Click += new System.EventHandler(this.btnPtintNumber_Click);
            // 
            // btnDelete
            // 
            this.btnDelete.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnDelete.Appearance.Options.UseFont = true;
            this.btnDelete.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnDelete.ImageOptions.Image")));
            this.btnDelete.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnDelete.Location = new System.Drawing.Point(497, 448);
            this.btnDelete.Name = "btnDelete";
            this.btnDelete.Size = new System.Drawing.Size(147, 51);
            this.btnDelete.TabIndex = 62;
            this.btnDelete.Text = "مسح التقرير المحدد";
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            // 
            // texInsert_Personal
            // 
            this.texInsert_Personal.Location = new System.Drawing.Point(720, 519);
            this.texInsert_Personal.Name = "texInsert_Personal";
            this.texInsert_Personal.ReadOnly = true;
            this.texInsert_Personal.Size = new System.Drawing.Size(149, 22);
            this.texInsert_Personal.TabIndex = 70;
            this.texInsert_Personal.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.ForeColor = System.Drawing.Color.Red;
            this.label7.Location = new System.Drawing.Point(385, 522);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(67, 16);
            this.label7.TabIndex = 72;
            this.label7.Text = "اسم الشريك :";
            // 
            // cbxAddType
            // 
            this.cbxAddType.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.SuggestAppend;
            this.cbxAddType.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cbxAddType.FormattingEnabled = true;
            this.cbxAddType.Location = new System.Drawing.Point(474, 517);
            this.cbxAddType.Name = "cbxAddType";
            this.cbxAddType.Size = new System.Drawing.Size(195, 24);
            this.cbxAddType.TabIndex = 71;
            this.cbxAddType.SelectionChangeCommitted += new System.EventHandler(this.CbxAddType_SelectionChangeCommitted);
            // 
            // Text_Total_Insert
            // 
            this.Text_Total_Insert.Location = new System.Drawing.Point(213, 516);
            this.Text_Total_Insert.Name = "Text_Total_Insert";
            this.Text_Total_Insert.ReadOnly = true;
            this.Text_Total_Insert.Size = new System.Drawing.Size(149, 22);
            this.Text_Total_Insert.TabIndex = 73;
            this.Text_Total_Insert.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // Frm_Sanad_Pull_Perso_Report
            // 
            this.Appearance.Options.UseFont = true;
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(923, 553);
            this.Controls.Add(this.Text_Total_Insert);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.cbxAddType);
            this.Controls.Add(this.texInsert_Personal);
            this.Controls.Add(this.btnPrintPersonal);
            this.Controls.Add(this.btnPrintAll);
            this.Controls.Add(this.btnPtintNumber);
            this.Controls.Add(this.rbtnAllStock);
            this.Controls.Add(this.rbtnOneStock);
            this.Controls.Add(this.label10);
            this.Controls.Add(this.cbxStock);
            this.Controls.Add(this.btnDelete);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.txtTotal);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.DgvSearch);
            this.Controls.Add(this.groupBox1);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.Margin = new System.Windows.Forms.Padding(4);
            this.MaximizeBox = false;
            this.Name = "Frm_Sanad_Pull_Perso_Report";
            this.RightToLeft = System.Windows.Forms.RightToLeft.Yes;
            this.RightToLeftLayout = true;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "شاشة تقارير سحب الشركاء";
            this.Load += new System.EventHandler(this.Frm_Sanad_Pull_Perso_Report_Load);
            ((System.ComponentModel.ISupportInitialize)(this.DgvSearch)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private DevExpress.XtraEditors.SimpleButton btnPrintPersonal;
        private DevExpress.XtraEditors.SimpleButton btnPrintAll;
        private DevExpress.XtraEditors.SimpleButton btnPtintNumber;
        private System.Windows.Forms.RadioButton rbtnAllStock;
        private System.Windows.Forms.RadioButton rbtnOneStock;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.ComboBox cbxStock;
        private DevExpress.XtraEditors.SimpleButton btnDelete;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox txtTotal;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.DataGridView DgvSearch;
        private System.Windows.Forms.GroupBox groupBox1;
        private DevExpress.XtraEditors.SimpleButton btnSearchPersonal;
        private System.Windows.Forms.TextBox txtSearch;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.DateTimePicker DtpTo;
        private System.Windows.Forms.DateTimePicker DtpFrom;
        private DevExpress.XtraEditors.SimpleButton btnSearchNumber;
        private System.Windows.Forms.TextBox texInsert_Personal;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.ComboBox cbxAddType;
        private System.Windows.Forms.TextBox Text_Total_Insert;
    }
}