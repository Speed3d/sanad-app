namespace Sales_Managment
{
    partial class Frm_SanadSarfReport
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Frm_SanadSarfReport));
            this.label3 = new System.Windows.Forms.Label();
            this.txtTotal = new System.Windows.Forms.TextBox();
            this.DgvSearch = new System.Windows.Forms.DataGridView();
            this.label2 = new System.Windows.Forms.Label();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.btnSearchNumper = new DevExpress.XtraEditors.SimpleButton();
            this.btnSearchDrainageType = new DevExpress.XtraEditors.SimpleButton();
            this.txtSearch = new System.Windows.Forms.TextBox();
            this.btnSearchType = new DevExpress.XtraEditors.SimpleButton();
            this.label1 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.DtpTo = new System.Windows.Forms.DateTimePicker();
            this.DtpFrom = new System.Windows.Forms.DateTimePicker();
            this.btnSearch = new DevExpress.XtraEditors.SimpleButton();
            this.cbxStock = new System.Windows.Forms.ComboBox();
            this.label10 = new System.Windows.Forms.Label();
            this.rbtnAllStock = new System.Windows.Forms.RadioButton();
            this.rbtnOneStock = new System.Windows.Forms.RadioButton();
            this.btnPrintSelect01 = new DevExpress.XtraEditors.SimpleButton();
            this.btnPrintAll = new DevExpress.XtraEditors.SimpleButton();
            this.btnPtintSelect = new DevExpress.XtraEditors.SimpleButton();
            this.btnDelete = new DevExpress.XtraEditors.SimpleButton();
            this.btnPrintSearchDrainage = new DevExpress.XtraEditors.SimpleButton();
            this.btnPrintNumber = new DevExpress.XtraEditors.SimpleButton();
            ((System.ComponentModel.ISupportInitialize)(this.DgvSearch)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.ForeColor = System.Drawing.Color.Red;
            this.label3.Location = new System.Drawing.Point(764, 477);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(216, 16);
            this.label3.TabIndex = 45;
            this.label3.Text = "اجمالي مبلغ السندات الصرف للفترة المحددة :";
            // 
            // txtTotal
            // 
            this.txtTotal.Location = new System.Drawing.Point(782, 442);
            this.txtTotal.Name = "txtTotal";
            this.txtTotal.ReadOnly = true;
            this.txtTotal.Size = new System.Drawing.Size(177, 22);
            this.txtTotal.TabIndex = 48;
            this.txtTotal.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
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
            dataGridViewCellStyle1.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(244)))), ((int)(((byte)(244)))), ((int)(((byte)(244)))));
            dataGridViewCellStyle1.SelectionBackColor = System.Drawing.Color.Yellow;
            dataGridViewCellStyle1.SelectionForeColor = System.Drawing.Color.Blue;
            dataGridViewCellStyle1.WrapMode = System.Windows.Forms.DataGridViewTriState.False;
            this.DgvSearch.DefaultCellStyle = dataGridViewCellStyle1;
            this.DgvSearch.Location = new System.Drawing.Point(17, 157);
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
            this.DgvSearch.Size = new System.Drawing.Size(963, 279);
            this.DgvSearch.TabIndex = 47;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 18F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.ForeColor = System.Drawing.Color.Red;
            this.label2.Location = new System.Drawing.Point(305, 4);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(276, 29);
            this.label2.TabIndex = 46;
            this.label2.Text = "اجمالي سندات الصرف في فترة";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.btnSearchNumper);
            this.groupBox1.Controls.Add(this.btnSearchDrainageType);
            this.groupBox1.Controls.Add(this.txtSearch);
            this.groupBox1.Controls.Add(this.btnSearchType);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.label4);
            this.groupBox1.Controls.Add(this.label6);
            this.groupBox1.Controls.Add(this.DtpTo);
            this.groupBox1.Controls.Add(this.DtpFrom);
            this.groupBox1.Controls.Add(this.btnSearch);
            this.groupBox1.Location = new System.Drawing.Point(213, 35);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(767, 105);
            this.groupBox1.TabIndex = 44;
            this.groupBox1.TabStop = false;
            this.groupBox1.Enter += new System.EventHandler(this.groupBox1_Enter);
            // 
            // btnSearchNumper
            // 
            this.btnSearchNumper.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearchNumper.Appearance.Options.UseFont = true;
            this.btnSearchNumper.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearchNumper.ImageOptions.Image")));
            this.btnSearchNumper.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearchNumper.Location = new System.Drawing.Point(166, 59);
            this.btnSearchNumper.Name = "btnSearchNumper";
            this.btnSearchNumper.Size = new System.Drawing.Size(116, 34);
            this.btnSearchNumper.TabIndex = 60;
            this.btnSearchNumper.Text = "بـحـث رقــم";
            this.btnSearchNumper.Click += new System.EventHandler(this.btnSearchNumper_Click);
            // 
            // btnSearchDrainageType
            // 
            this.btnSearchDrainageType.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearchDrainageType.Appearance.Options.UseFont = true;
            this.btnSearchDrainageType.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearchDrainageType.ImageOptions.Image")));
            this.btnSearchDrainageType.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearchDrainageType.Location = new System.Drawing.Point(429, 58);
            this.btnSearchDrainageType.Name = "btnSearchDrainageType";
            this.btnSearchDrainageType.Size = new System.Drawing.Size(128, 35);
            this.btnSearchDrainageType.TabIndex = 59;
            this.btnSearchDrainageType.Text = "بحث نوع الصرف";
            this.btnSearchDrainageType.Click += new System.EventHandler(this.btnSearchDrainageType_Click);
            // 
            // txtSearch
            // 
            this.txtSearch.Location = new System.Drawing.Point(7, 21);
            this.txtSearch.Multiline = true;
            this.txtSearch.Name = "txtSearch";
            this.txtSearch.Size = new System.Drawing.Size(336, 29);
            this.txtSearch.TabIndex = 57;
            this.txtSearch.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // btnSearchType
            // 
            this.btnSearchType.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearchType.Appearance.Options.UseFont = true;
            this.btnSearchType.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearchType.ImageOptions.Image")));
            this.btnSearchType.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearchType.Location = new System.Drawing.Point(302, 59);
            this.btnSearchType.Name = "btnSearchType";
            this.btnSearchType.Size = new System.Drawing.Size(108, 35);
            this.btnSearchType.TabIndex = 58;
            this.btnSearchType.Text = "بحث التصنيف";
            this.btnSearchType.Click += new System.EventHandler(this.btnSearchType_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.ForeColor = System.Drawing.Color.Red;
            this.label1.Location = new System.Drawing.Point(715, 71);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(42, 16);
            this.label1.TabIndex = 10;
            this.label1.Text = "الــــى :";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.ForeColor = System.Drawing.Color.Red;
            this.label4.Location = new System.Drawing.Point(716, 26);
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
            this.label6.Location = new System.Drawing.Point(339, 25);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(249, 17);
            this.label6.TabIndex = 56;
            this.label6.Text = "اكتب الاسم او جزء من الاسم الذي تريد البحث عنه : ";
            // 
            // DtpTo
            // 
            this.DtpTo.Format = System.Windows.Forms.DateTimePickerFormat.Short;
            this.DtpTo.Location = new System.Drawing.Point(594, 63);
            this.DtpTo.Name = "DtpTo";
            this.DtpTo.Size = new System.Drawing.Size(115, 22);
            this.DtpTo.TabIndex = 8;
            // 
            // DtpFrom
            // 
            this.DtpFrom.Format = System.Windows.Forms.DateTimePickerFormat.Short;
            this.DtpFrom.Location = new System.Drawing.Point(594, 22);
            this.DtpFrom.Name = "DtpFrom";
            this.DtpFrom.Size = new System.Drawing.Size(115, 22);
            this.DtpFrom.TabIndex = 7;
            // 
            // btnSearch
            // 
            this.btnSearch.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSearch.Appearance.Options.UseFont = true;
            this.btnSearch.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnSearch.ImageOptions.Image")));
            this.btnSearch.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnSearch.Location = new System.Drawing.Point(16, 59);
            this.btnSearch.Name = "btnSearch";
            this.btnSearch.Size = new System.Drawing.Size(133, 34);
            this.btnSearch.TabIndex = 40;
            this.btnSearch.Text = "بحث التفاصيــل";
            this.btnSearch.Click += new System.EventHandler(this.btnSearch_Click);
            // 
            // cbxStock
            // 
            this.cbxStock.AutoCompleteMode = System.Windows.Forms.AutoCompleteMode.SuggestAppend;
            this.cbxStock.AutoCompleteSource = System.Windows.Forms.AutoCompleteSource.ListItems;
            this.cbxStock.FormattingEnabled = true;
            this.cbxStock.Location = new System.Drawing.Point(14, 98);
            this.cbxStock.Name = "cbxStock";
            this.cbxStock.Size = new System.Drawing.Size(193, 24);
            this.cbxStock.TabIndex = 50;
            this.cbxStock.SelectionChangeCommitted += new System.EventHandler(this.cbxStock_SelectionChangeCommitted);
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label10.ForeColor = System.Drawing.Color.Red;
            this.label10.Location = new System.Drawing.Point(14, 45);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(67, 18);
            this.label10.TabIndex = 51;
            this.label10.Text = "اختر الخزنة";
            // 
            // rbtnAllStock
            // 
            this.rbtnAllStock.AutoSize = true;
            this.rbtnAllStock.Checked = true;
            this.rbtnAllStock.ForeColor = System.Drawing.Color.Blue;
            this.rbtnAllStock.Location = new System.Drawing.Point(90, 26);
            this.rbtnAllStock.Name = "rbtnAllStock";
            this.rbtnAllStock.Size = new System.Drawing.Size(82, 20);
            this.rbtnAllStock.TabIndex = 53;
            this.rbtnAllStock.TabStop = true;
            this.rbtnAllStock.Text = "كل الخزنات";
            this.rbtnAllStock.UseVisualStyleBackColor = true;
            this.rbtnAllStock.CheckedChanged += new System.EventHandler(this.rbtnAllStock_CheckedChanged);
            // 
            // rbtnOneStock
            // 
            this.rbtnOneStock.AutoSize = true;
            this.rbtnOneStock.ForeColor = System.Drawing.Color.Blue;
            this.rbtnOneStock.Location = new System.Drawing.Point(90, 61);
            this.rbtnOneStock.Name = "rbtnOneStock";
            this.rbtnOneStock.Size = new System.Drawing.Size(94, 20);
            this.rbtnOneStock.TabIndex = 52;
            this.rbtnOneStock.Text = "الخزنة المحددة";
            this.rbtnOneStock.UseVisualStyleBackColor = true;
            this.rbtnOneStock.CheckedChanged += new System.EventHandler(this.rbtnOneStock_CheckedChanged);
            // 
            // btnPrintSelect01
            // 
            this.btnPrintSelect01.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintSelect01.Appearance.Options.UseFont = true;
            this.btnPrintSelect01.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintSelect01.ImageOptions.Image")));
            this.btnPrintSelect01.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintSelect01.Location = new System.Drawing.Point(270, 442);
            this.btnPrintSelect01.Name = "btnPrintSelect01";
            this.btnPrintSelect01.Size = new System.Drawing.Size(143, 51);
            this.btnPrintSelect01.TabIndex = 56;
            this.btnPrintSelect01.Text = "طباعة الخزنة المحددة\r\nوتصنيف محددة";
            this.btnPrintSelect01.Click += new System.EventHandler(this.btnPrintSelect01_Click);
            // 
            // btnPrintAll
            // 
            this.btnPrintAll.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintAll.Appearance.Options.UseFont = true;
            this.btnPrintAll.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintAll.ImageOptions.Image")));
            this.btnPrintAll.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintAll.Location = new System.Drawing.Point(17, 441);
            this.btnPrintAll.Name = "btnPrintAll";
            this.btnPrintAll.Size = new System.Drawing.Size(94, 51);
            this.btnPrintAll.TabIndex = 55;
            this.btnPrintAll.Text = "طباعة الكل";
            this.btnPrintAll.Click += new System.EventHandler(this.btnPrintAll_Click);
            // 
            // btnPtintSelect
            // 
            this.btnPtintSelect.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPtintSelect.Appearance.Options.UseFont = true;
            this.btnPtintSelect.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPtintSelect.ImageOptions.Image")));
            this.btnPtintSelect.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPtintSelect.Location = new System.Drawing.Point(556, 442);
            this.btnPtintSelect.Name = "btnPtintSelect";
            this.btnPtintSelect.Size = new System.Drawing.Size(151, 51);
            this.btnPtintSelect.TabIndex = 54;
            this.btnPtintSelect.Text = "طباعة الخزنة المحددة\r\nوتفاصيل محددة";
            this.btnPtintSelect.Click += new System.EventHandler(this.btnPtintSelect_Click);
            // 
            // btnDelete
            // 
            this.btnDelete.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnDelete.Appearance.Options.UseFont = true;
            this.btnDelete.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnDelete.ImageOptions.Image")));
            this.btnDelete.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnDelete.Location = new System.Drawing.Point(713, 442);
            this.btnDelete.Name = "btnDelete";
            this.btnDelete.Size = new System.Drawing.Size(45, 51);
            this.btnDelete.TabIndex = 49;
            this.btnDelete.Text = "مسح التقرير المحدد";
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            // 
            // btnPrintSearchDrainage
            // 
            this.btnPrintSearchDrainage.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintSearchDrainage.Appearance.Options.UseFont = true;
            this.btnPrintSearchDrainage.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintSearchDrainage.ImageOptions.Image")));
            this.btnPrintSearchDrainage.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintSearchDrainage.Location = new System.Drawing.Point(115, 442);
            this.btnPrintSearchDrainage.Name = "btnPrintSearchDrainage";
            this.btnPrintSearchDrainage.Size = new System.Drawing.Size(151, 51);
            this.btnPrintSearchDrainage.TabIndex = 57;
            this.btnPrintSearchDrainage.Text = "طباعة الخزنة المحددة\r\nونوع صرف محدد";
            this.btnPrintSearchDrainage.Click += new System.EventHandler(this.btnPrintSearchDrainage_Click);
            // 
            // btnPrintNumber
            // 
            this.btnPrintNumber.Appearance.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPrintNumber.Appearance.Options.UseFont = true;
            this.btnPrintNumber.ImageOptions.Image = ((System.Drawing.Image)(resources.GetObject("btnPrintNumber.ImageOptions.Image")));
            this.btnPrintNumber.ImageOptions.ImageToTextAlignment = DevExpress.XtraEditors.ImageAlignToText.RightTop;
            this.btnPrintNumber.Location = new System.Drawing.Point(419, 442);
            this.btnPrintNumber.Name = "btnPrintNumber";
            this.btnPrintNumber.Size = new System.Drawing.Size(132, 51);
            this.btnPrintNumber.TabIndex = 58;
            this.btnPrintNumber.Text = "طباعة الخزنة المحددة\r\nونوع رقم محدد";
            this.btnPrintNumber.Click += new System.EventHandler(this.btnPrintNumber_Click);
            // 
            // Frm_SanadSarfReport
            // 
            this.Appearance.Options.UseFont = true;
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(992, 507);
            this.Controls.Add(this.btnPrintNumber);
            this.Controls.Add(this.btnPrintSearchDrainage);
            this.Controls.Add(this.btnPrintSelect01);
            this.Controls.Add(this.btnPrintAll);
            this.Controls.Add(this.btnPtintSelect);
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
            this.Margin = new System.Windows.Forms.Padding(5, 6, 5, 6);
            this.MaximizeBox = false;
            this.Name = "Frm_SanadSarfReport";
            this.RightToLeft = System.Windows.Forms.RightToLeft.Yes;
            this.RightToLeftLayout = true;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "تقرير سندات القبض والصرف";
            this.Load += new System.EventHandler(this.Frm_SanadSarfReport_Load);
            ((System.ComponentModel.ISupportInitialize)(this.DgvSearch)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private DevExpress.XtraEditors.SimpleButton btnDelete;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox txtTotal;
        private System.Windows.Forms.DataGridView DgvSearch;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.DateTimePicker DtpTo;
        private System.Windows.Forms.DateTimePicker DtpFrom;
        private DevExpress.XtraEditors.SimpleButton btnSearch;
        private System.Windows.Forms.ComboBox cbxStock;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.RadioButton rbtnAllStock;
        private System.Windows.Forms.RadioButton rbtnOneStock;
        private DevExpress.XtraEditors.SimpleButton btnPrintAll;
        private DevExpress.XtraEditors.SimpleButton btnPtintSelect;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TextBox txtSearch;
        private DevExpress.XtraEditors.SimpleButton btnSearchType;
        private DevExpress.XtraEditors.SimpleButton btnPrintSelect01;
        private DevExpress.XtraEditors.SimpleButton btnSearchDrainageType;
        private DevExpress.XtraEditors.SimpleButton btnPrintSearchDrainage;
        private DevExpress.XtraEditors.SimpleButton btnSearchNumper;
        private DevExpress.XtraEditors.SimpleButton btnPrintNumber;
    }
}