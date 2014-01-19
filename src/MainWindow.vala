/*
 * MainWindow.vala
 * 
 * Copyright 2013 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.DiskPartition;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MainWindow : Window {
	private Box vbox_main;
	private Box vbox_actions;
	private Box vbox_packages;
	private Box vbox_ppa;
	private Box vbox_theme;
	
	private Grid grid_backup_buttons;
	private Grid grid_option_buttons;
	
	private Notebook notebook;
	private FileChooserButton fcb_backup;
	private Button btn_about;
	
	private Button btn_restore_ppa;
	private Button btn_restore_ppa_exec;
	private Button btn_backup_ppa;
	private Button btn_backup_ppa_exec;
	private Button btn_backup_ppa_cancel;
	private Button btn_backup_ppa_select_all;
	private Button btn_backup_ppa_select_none;
	
	private Button btn_restore_packages;
	private Button btn_restore_packages_exec;
	private Button btn_backup_packages;
	private Button btn_backup_packages_exec;
	private Button btn_backup_packages_cancel;
	private Button btn_backup_packages_select_all;
	private Button btn_backup_packages_select_none;
	
	private Button btn_restore_cache;
	private Button btn_backup_cache;
	
	private Button btn_restore_theme;
	private Button btn_restore_theme_exec;
	private Button btn_backup_theme;
	private Button btn_backup_theme_exec;
	private Button btn_backup_theme_cancel;
	private Button btn_backup_theme_select_all;
	private Button btn_backup_theme_select_none;
	
	private Button btn_take_ownership;

	private TreeView tv_packages;
	private TreeView tv_ppa;
	private TreeView tv_theme;
	private TreeViewColumn col_ppa_status;
	private TreeViewColumn col_pkg_status;
	private TreeViewColumn col_theme_status;
	
	private ScrolledWindow sw_packages;
	private ScrolledWindow sw_ppa;
	private ScrolledWindow sw_theme;
	private ProgressBar progressbar;
	private Label lbl_status;
	private Label lbl_packages_message;
	private Label lbl_ppa_message;
	private Label lbl_theme_message;

	private Gee.HashMap<string,Package> pkg_list_user;
	private Gee.HashMap<string,Package> pkg_list_all;
	private Gee.HashMap<string,Ppa> ppa_list_user;
	private Gee.ArrayList<Theme> theme_list_user;
	private string list_install;
	private string list_unknown;
	string summary = "";

	bool is_running;
	bool is_restore_view = false;
	int def_width = 480;
	int def_height = 400;
	
	public MainWindow () {
		title = AppName + " v" + AppVersion;// + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        window_position = WindowPosition.CENTER;
        //resizable = false;
        destroy.connect (Gtk.main_quit);
        set_default_size (def_width, def_height);	

        //set app icon
		try{
			this.icon = new Gdk.Pixbuf.from_file ("""/usr/share/pixmaps/aptik.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
	    //vboxMain
        vbox_main = new Box (Orientation.VERTICAL, 0);
        vbox_main.margin = 3;
        add (vbox_main);
		
		//notebook
		notebook = new Notebook ();
		//notebook.margin = 6;
		notebook.show_tabs = false;
		//notebook.show_border = false;
		vbox_main.pack_start (notebook, true, true, 0);
		
        //actions ---------------------------------------------
		
		//lbl_actions
		Label lbl_actions = new Label (_("Actions"));

        //vbox_actions
        vbox_actions = new Box (Gtk.Orientation.VERTICAL, 6);
        vbox_actions.margin = 6;
        notebook.append_page (vbox_actions, lbl_actions);
        
        // lbl_header_location
		Label lbl_header_location = new Label ("<b>" + _("Backup Directory") + "</b>");
		lbl_header_location.set_use_markup(true);
		lbl_header_location.halign = Align.START;
		lbl_header_location.margin_top = 6;
		lbl_header_location.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_location, false, true, 0);
		
		// fcb_backup
		fcb_backup = new FileChooserButton (_("Backup Directory"), FileChooserAction.SELECT_FOLDER);
		fcb_backup.margin_left = 6;
		fcb_backup.margin_bottom = 6;
		if ((App.backup_dir != null) && dir_exists (App.backup_dir)){
			fcb_backup.set_filename (App.backup_dir);
		}
		vbox_actions.pack_start (fcb_backup, false, true, 0);

		fcb_backup.file_set.connect(()=>{
			App.backup_dir = fcb_backup.get_filename() + "/";
		});

        // lbl_header_backup
		Label lbl_header_backup = new Label ("<b>" + _("Backup &amp; Restore") + "</b>");
		lbl_header_backup.set_use_markup(true);
		lbl_header_backup.halign = Align.START;
		lbl_header_backup.margin_top = 6;
		lbl_header_backup.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_backup, false, true, 0);
		
		//grid_backup_buttons
        grid_backup_buttons = new Grid();
        grid_backup_buttons.set_column_spacing (6);
        grid_backup_buttons.set_row_spacing (6);
        grid_backup_buttons.margin_left = 6;
        vbox_actions.pack_start (grid_backup_buttons, false, true, 0);
        
        int row = -1;
        
        //lbl_backup_ppa
		Label lbl_backup_ppa = new Label (_("Software Sources (PPAs)"));
		lbl_backup_ppa.set_tooltip_text(_("Software Sources (Third Party PPAs)"));
		lbl_backup_ppa.set_use_markup(true);
		lbl_backup_ppa.halign = Align.START;
		lbl_backup_ppa.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_ppa,0,++row,1,1);
		
		//btn_backup_ppa
		btn_backup_ppa = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_ppa.set_size_request(50,-1);
		btn_backup_ppa.set_tooltip_text(_("Backup the list of installed PPAs"));
		grid_backup_buttons.attach(btn_backup_ppa,1,row,1,1);

		btn_backup_ppa.clicked.connect(btn_backup_ppa_clicked);
		
		//btn_restore_ppa
		btn_restore_ppa = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_ppa.set_size_request(50,-1);
		btn_restore_ppa.set_tooltip_text(_("Add missing PPAs"));
		grid_backup_buttons.attach(btn_restore_ppa,2,row,1,1);
		
		btn_restore_ppa.clicked.connect(btn_restore_ppa_clicked);
		
        //lbl_backup_packages
		Label lbl_backup_packages = new Label (_("Software Selections"));
		lbl_backup_packages.set_tooltip_text(_("Software Selections (Manually Installed Packages)"));
		lbl_backup_packages.set_use_markup(true);
		lbl_backup_packages.halign = Align.START;
		lbl_backup_packages.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_packages,0,++row,1,1);
		
		//btn_backup_packages
		btn_backup_packages = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_packages.set_size_request(50,-1);
		btn_backup_packages.set_tooltip_text(_("Backup the list of installed packages"));
		grid_backup_buttons.attach(btn_backup_packages,1,row,1,1);
		
		btn_backup_packages.clicked.connect(btn_backup_packages_clicked);

		//btn_restore_packages
		btn_restore_packages = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_packages.set_size_request(50,-1);
		btn_restore_packages.set_tooltip_text(_("Install missing packages"));
		grid_backup_buttons.attach(btn_restore_packages,2,row,1,1);
		
		btn_restore_packages.clicked.connect(btn_restore_packages_clicked);

        //lbl_backup_cache
		Label lbl_backup_cache = new Label (_("Downloaded Packages (APT Cache)"));
		lbl_backup_cache.set_tooltip_text(_("Downloaded Packages (APT Cache)"));
		lbl_backup_cache.set_use_markup(true);
		lbl_backup_cache.halign = Align.START;
		lbl_backup_cache.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_cache,0,++row,1,1);
		
		//btn_backup_cache
		btn_backup_cache = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_cache.set_size_request(80,-1);
		btn_backup_cache.set_tooltip_text(_("Backup downloaded packages from APT cache"));
		btn_backup_cache.clicked.connect(btn_backup_cache_clicked);
		grid_backup_buttons.attach(btn_backup_cache,1,row,1,1);
		
		//btn_restore_cache
		btn_restore_cache = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_cache.set_size_request(80,-1);
		btn_restore_cache.set_tooltip_text(_("Restore downloaded packages to APT cache"));
		btn_restore_cache.clicked.connect(btn_restore_cache_clicked);
		grid_backup_buttons.attach(btn_restore_cache,2,row,1,1);

        //lbl_backup_theme
		Label lbl_backup_theme = new Label (_("Themes and Icons"));
		lbl_backup_theme.set_tooltip_text(_("Themes and Icons"));
		lbl_backup_theme.set_use_markup(true);
		lbl_backup_theme.halign = Align.START;
		lbl_backup_theme.hexpand = true;
		grid_backup_buttons.attach(lbl_backup_theme,0,++row,1,1);
		
		//btn_backup_theme
		btn_backup_theme = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_theme.set_size_request(50,-1);
		btn_backup_theme.set_tooltip_text(_("Backup themes and icons"));
		grid_backup_buttons.attach(btn_backup_theme,1,row,1,1);
		
		btn_backup_theme.clicked.connect(btn_backup_theme_clicked);

		//btn_restore_theme
		btn_restore_theme = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_theme.set_size_request(50,-1);
		btn_restore_theme.set_tooltip_text(_("Restore themes and icons"));
		grid_backup_buttons.attach(btn_restore_theme,2,row,1,1);
		
		btn_restore_theme.clicked.connect(btn_restore_theme_clicked);
		
        // lbl_header_tools
		Label lbl_header_tools = new Label ("<b>" + _("Options") + "</b>");
		lbl_header_tools.set_use_markup(true);
		lbl_header_tools.halign = Align.START;
		lbl_header_tools.margin_top = 6;
		lbl_header_tools.margin_bottom = 6;
		vbox_actions.pack_start (lbl_header_tools, false, true, 0);
		
		//grid_option_buttons
        grid_option_buttons = new Grid();
        grid_option_buttons.set_column_spacing (6);
        grid_option_buttons.set_row_spacing (6);
        grid_option_buttons.margin_left = 6;
        vbox_actions.pack_start (grid_option_buttons, false, true, 0);
        
        row = -1;
        
        //lbl_take_ownership
		Label lbl_take_ownership = new Label (_("Fix Ownership of files in Home directory"));
		lbl_take_ownership.set_use_markup(true);
		lbl_take_ownership.halign = Align.START;
		lbl_take_ownership.hexpand = true;
		grid_option_buttons.attach(lbl_take_ownership,0,++row,1,1);

		//btn_take_ownership
		btn_take_ownership = new Gtk.Button.with_label (" " + _("Take Ownership") + " ");
		btn_take_ownership.set_size_request(172,-1);
		btn_take_ownership.set_tooltip_text(_("Take ownership of files in your home directory"));
		btn_take_ownership.clicked.connect(btn_take_ownership_clicked);
		grid_option_buttons.attach(btn_take_ownership,1,row,1,1);

		//btn_about
		btn_about = new Gtk.Button.with_label (" " + _("Application Info") + " ");
		btn_about.set_size_request(150,-1);
		btn_about.set_tooltip_text(_("About Aptik"));
		btn_about.clicked.connect(btn_about_clicked);
		
		Box hbox_about = new Box(Orientation.HORIZONTAL,0);
		hbox_about.pack_start (btn_about, true, false, 0);
		vbox_actions.pack_end (hbox_about, false, false, 0);

        //select packages ---------------------------------------------
		
		//lbl_packages
		Label lbl_packages = new Label (_("Packages"));

        //vbox_packages
        vbox_packages = new Box (Gtk.Orientation.VERTICAL, 6);
        vbox_packages.margin = 6;
        notebook.append_page (vbox_packages, lbl_packages);
        
        //lbl_header_packages
		Label lbl_header_packages = new Label ("<b>" + _("Backup Installed Applications") + "</b>");
		lbl_header_packages.set_use_markup(true);
		lbl_header_packages.halign = Align.START;
		lbl_header_packages.margin_top = 6;
		//lbl_header_packages.margin_bottom = 6;
		//vbox_packages.pack_start (lbl_header_packages, false, true, 0);
		
        //lbl_packages
		lbl_packages_message = new Label (_("Select the packages to backup"));
		lbl_packages_message.set_use_markup(true);
		lbl_packages_message.halign = Align.START;
		lbl_packages_message.xalign = (float) 0.0;
		lbl_packages_message.wrap = true;
		vbox_packages.pack_start (lbl_packages_message, false, true, 0);
		
		//package treeview --------------------------------------------------
		
		//tv_packages
		tv_packages = new TreeView();
		tv_packages.get_selection().mode = SelectionMode.MULTIPLE;
		tv_packages.headers_clickable = true;
		tv_packages.set_rules_hint (true);
		tv_packages.set_tooltip_column(3);
		
		//sw_packages
		sw_packages = new ScrolledWindow(null, null);
		sw_packages.set_shadow_type (ShadowType.ETCHED_IN);
		sw_packages.add (tv_packages);
		sw_packages.expand = true;
		vbox_packages.add(sw_packages);

		//col_pkg_select ----------------------
		
		TreeViewColumn col_pkg_select = new TreeViewColumn();
		tv_packages.append_column(col_pkg_select);

		CellRendererToggle cell_pkg_select = new CellRendererToggle ();
		cell_pkg_select.activatable = true;
		col_pkg_select.pack_start (cell_pkg_select, false);
		
		col_pkg_select.set_cell_data_func (cell_pkg_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Package pkg;
			model.get (iter, 0, out selected, 1, out pkg,-1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || (pkg.is_available && !pkg.is_installed);
		});
		
		cell_pkg_select.toggled.connect((path) => {
			TreeIter iter;
			ListStore model = (ListStore)tv_packages.model;
			bool selected;
			Package pkg;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out pkg);
			model.set (iter, 0, !selected);
			pkg.is_selected = !selected;
		});

		//col_pkg_status ----------------------
		
		col_pkg_status = new TreeViewColumn();
		//col_pkg_status.title = _("");
		col_pkg_status.resizable = true;
		tv_packages.append_column(col_pkg_status);
		
		CellRendererPixbuf cell_pkg_status = new CellRendererPixbuf ();
		col_pkg_status.pack_start (cell_pkg_status, false);
		col_pkg_status.set_attributes(cell_pkg_status, "pixbuf", 2);
		
		//col_pkg_name ----------------------
		
		TreeViewColumn col_pkg_name = new TreeViewColumn();
		col_pkg_name.title = _("Package");
		col_pkg_name.resizable = true;
		tv_packages.append_column(col_pkg_name);

		CellRendererText cell_pkg_name = new CellRendererText ();
		cell_pkg_name.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_name.pack_start (cell_pkg_name, false);

		col_pkg_name.set_cell_data_func (cell_pkg_name, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.name;
		});

		//col_pkg_desc ----------------------
		
		TreeViewColumn col_pkg_desc = new TreeViewColumn();
		col_pkg_desc.title = _("Description");
		col_pkg_desc.resizable = true;
		tv_packages.append_column(col_pkg_desc);

		CellRendererText cell_pkg_desc = new CellRendererText ();
		cell_pkg_desc.ellipsize = Pango.EllipsizeMode.END;
		col_pkg_desc.pack_start (cell_pkg_desc, false);

		col_pkg_desc.set_cell_data_func (cell_pkg_desc, (cell_layout, cell, model, iter) => {
			Package pkg;
			model.get (iter, 1, out pkg, -1);
			(cell as Gtk.CellRendererText).text = pkg.description;
		});

		//hbox_pkg_actions
		Box hbox_pkg_actions = new Box (Orientation.HORIZONTAL, 6);
        vbox_packages.add (hbox_pkg_actions);

		//btn_backup_packages_select_all
		btn_backup_packages_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_select_all, true, true, 0);
		btn_backup_packages_select_all.clicked.connect(()=>{ 
			foreach(Package pkg in pkg_list_user.values){
				if (is_restore_view){
					if (pkg.is_available && !pkg.is_installed){
						pkg.is_selected = true;
					}
					else{
						//no change
					}
				}
				else{
					pkg.is_selected = true;
				}
			}
			tv_packages_refresh();
		});
		
		//btn_backup_packages_select_none
		btn_backup_packages_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_select_none, true, true, 0);
		btn_backup_packages_select_none.clicked.connect(()=>{ 
			foreach(Package pkg in pkg_list_user.values){
				if (is_restore_view){
					if (pkg.is_available && !pkg.is_installed){
						pkg.is_selected = false;
					}
					else{
						//no change
					}
				}
				else{
					pkg.is_selected = false;
				}
			}
			tv_packages_refresh();
		});
		
		//btn_backup_packages_exec
		btn_backup_packages_exec = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_packages_exec.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_backup_packages_exec, true, true, 0);
		btn_backup_packages_exec.clicked.connect(btn_backup_packages_exec_clicked);

		//btn_restore_packages_exec
		btn_restore_packages_exec = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_packages_exec.no_show_all = true;
		hbox_pkg_actions.pack_start (btn_restore_packages_exec, true, true, 0);
		btn_restore_packages_exec.clicked.connect(btn_restore_packages_exec_clicked);

		//btn_backup_packages_cancel
		btn_backup_packages_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_pkg_actions.pack_start (btn_backup_packages_cancel, true, true, 0);
		btn_backup_packages_cancel.clicked.connect(()=>{ 
			show_home_page();
		});

		//select ppa ---------------------------------------------
		
		//lbl_ppa
		Label lbl_ppa = new Label (_("PPA"));

        //vbox_ppa
        vbox_ppa = new Box (Gtk.Orientation.VERTICAL, 6);
        vbox_ppa.margin = 6;
        notebook.append_page (vbox_ppa, lbl_ppa);
        
        //lbl_header_ppa
		Label lbl_header_ppa = new Label ("<b>" + _("Backup PPA List") + "</b>");
		lbl_header_ppa.set_use_markup(true);
		lbl_header_ppa.halign = Align.START;
		lbl_header_ppa.margin_top = 6;
		//lbl_header_ppa.margin_bottom = 6;
		//vbox_ppa.pack_start (lbl_header_ppa, false, true, 0);
		
        //lbl_ppa
		lbl_ppa_message = new Label (_("Select the PPAs to backup"));
		lbl_ppa_message.set_use_markup(true);
		lbl_ppa_message.halign = Align.START;
		vbox_ppa.pack_start (lbl_ppa_message, false, true, 0);
		
		//ppa treeview --------------------------------------------------
		
		//tv_ppa
		tv_ppa = new TreeView();
		tv_ppa.get_selection().mode = SelectionMode.MULTIPLE;
		tv_ppa.headers_clickable = true;
		tv_ppa.set_rules_hint (true);
		tv_ppa.set_tooltip_column(3);
		
		//sw_ppa
		sw_ppa = new ScrolledWindow(null, null);
		sw_ppa.set_shadow_type (ShadowType.ETCHED_IN);
		sw_ppa.add (tv_ppa);
		sw_ppa.expand = true;
		vbox_ppa.add(sw_ppa);

		//col_ppa_select ----------------------
		
		TreeViewColumn col_ppa_select = new TreeViewColumn();
		col_ppa_select.title = " " + _("") + " ";
		CellRendererToggle cell_ppa_select = new CellRendererToggle ();
		cell_ppa_select.activatable = true;
		col_ppa_select.pack_start (cell_ppa_select, false);
		tv_ppa.append_column(col_ppa_select);

		col_ppa_select.set_cell_data_func (cell_ppa_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Ppa ppa;
			model.get (iter, 0, out selected, 1, out ppa, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || !ppa.is_installed;
		});
		
		cell_ppa_select.toggled.connect((path) => {
			TreeIter iter;
			ListStore model = (ListStore)tv_ppa.model;
			bool selected;
			Ppa ppa;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out ppa);
			model.set (iter, 0, !selected);
			ppa.is_selected = !selected;
		});

		//col_ppa_status ----------------------
		
		col_ppa_status = new TreeViewColumn();
		//col_ppa_status.title = _("");
		col_ppa_status.resizable = true;
		tv_ppa.append_column(col_ppa_status);
		
		CellRendererPixbuf cell_ppa_status = new CellRendererPixbuf ();
		col_ppa_status.pack_start (cell_ppa_status, false);
		col_ppa_status.set_attributes(cell_ppa_status, "pixbuf", 2);
		
		//col_ppa_name ----------------------
		
		TreeViewColumn col_ppa_name = new TreeViewColumn();
		col_ppa_name.title = _("PPA");
		col_ppa_name.resizable = true;
		tv_ppa.append_column(col_ppa_name);

		CellRendererText cell_ppa_name = new CellRendererText ();
		cell_ppa_name.ellipsize = Pango.EllipsizeMode.END;
		col_ppa_name.pack_start (cell_ppa_name, false);

		col_ppa_name.set_cell_data_func (cell_ppa_name, (cell_layout, cell, model, iter) => {
			Ppa ppa;
			model.get (iter, 1, out ppa, -1);
			(cell as Gtk.CellRendererText).text = ppa.name;
		});
		
		//col_ppa_desc ----------------------
		
		TreeViewColumn col_ppa_desc = new TreeViewColumn();
		col_ppa_desc.title = _("Packages");
		col_ppa_desc.resizable = true;
		tv_ppa.append_column(col_ppa_desc);
		
		CellRendererText cell_ppa_desc = new CellRendererText ();
		cell_ppa_desc.ellipsize = Pango.EllipsizeMode.END;
		col_ppa_desc.pack_start (cell_ppa_desc, false);

		col_ppa_desc.set_cell_data_func (cell_ppa_desc, (cell_layout, cell, model, iter) => {
			Ppa ppa;
			model.get (iter, 1, out ppa, -1);
			(cell as Gtk.CellRendererText).text = ppa.description;
		});

		//hbox_ppa_actions
		Box hbox_ppa_actions = new Box (Orientation.HORIZONTAL, 6);
        vbox_ppa.add (hbox_ppa_actions);

		//btn_backup_ppa_select_all
		btn_backup_ppa_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_select_all, true, true, 0);
		btn_backup_ppa_select_all.clicked.connect(()=>{ 
			foreach(Ppa ppa in ppa_list_user.values){
				if (is_restore_view){
					if (!ppa.is_installed){
						ppa.is_selected = true;
					}
					else{
						//no change
					}
				}
				else{
					ppa.is_selected = true;
				}
			}
			tv_ppa_refresh();
		});
		
		//btn_backup_ppa_select_none
		btn_backup_ppa_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_select_none, true, true, 0);
		btn_backup_ppa_select_none.clicked.connect(()=>{ 
			foreach(Ppa ppa in ppa_list_user.values){
				if (is_restore_view){
					if (!ppa.is_installed){
						ppa.is_selected = false;
					}
					else{
						//no change
					}
				}
				else{
					ppa.is_selected = false;
				}
			}
			tv_ppa_refresh();
		});
		
		//btn_backup_ppa_exec
		btn_backup_ppa_exec = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_ppa_exec.no_show_all = true;
		hbox_ppa_actions.pack_start (btn_backup_ppa_exec, true, true, 0);
		btn_backup_ppa_exec.clicked.connect(btn_backup_ppa_exec_clicked);

		//btn_restore_ppa_exec
		btn_restore_ppa_exec = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_ppa_exec.no_show_all = true;
		hbox_ppa_actions.pack_start (btn_restore_ppa_exec, true, true, 0);
		btn_restore_ppa_exec.clicked.connect(btn_restore_ppa_exec_clicked);
		
		//btn_backup_ppa_cancel
		btn_backup_ppa_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_ppa_actions.pack_start (btn_backup_ppa_cancel, true, true, 0);
		btn_backup_ppa_cancel.clicked.connect(()=>{ 
			show_home_page();
		});
		
		//select theme ---------------------------------------------
		
		//lbl_theme
		Label lbl_theme = new Label (_("Theme"));

        //vbox_theme
        vbox_theme = new Box (Gtk.Orientation.VERTICAL, 6);
        vbox_theme.margin = 6;
        notebook.append_page (vbox_theme, lbl_theme);
        
        //lbl_header_theme
		Label lbl_header_theme = new Label ("<b>" + _("Backup Themes and Icons") + "</b>");
		lbl_header_theme.set_use_markup(true);
		lbl_header_theme.halign = Align.START;
		lbl_header_theme.margin_top = 6;
		//lbl_header_theme.margin_bottom = 6;
		//vbox_theme.pack_start (lbl_header_theme, false, true, 0);
		
        //lbl_theme
		lbl_theme_message = new Label (_("Select the themes to backup"));
		lbl_theme_message.set_use_markup(true);
		lbl_theme_message.halign = Align.START;
		vbox_theme.pack_start (lbl_theme_message, false, true, 0);
		
		//theme treeview --------------------------------------------------
		
		//tv_theme
		tv_theme = new TreeView();
		tv_theme.get_selection().mode = SelectionMode.MULTIPLE;
		tv_theme.headers_clickable = true;
		tv_theme.set_rules_hint (true);
		tv_theme.set_tooltip_column(3);
		
		//sw_theme
		sw_theme = new ScrolledWindow(null, null);
		sw_theme.set_shadow_type (ShadowType.ETCHED_IN);
		sw_theme.add (tv_theme);
		sw_theme.expand = true;
		vbox_theme.add(sw_theme);

		//col_theme_select ----------------------
		
		TreeViewColumn col_theme_select = new TreeViewColumn();
		col_theme_select.title = " " + _("") + " ";
		CellRendererToggle cell_theme_select = new CellRendererToggle ();
		cell_theme_select.activatable = true;
		col_theme_select.pack_start (cell_theme_select, false);
		tv_theme.append_column(col_theme_select);

		col_theme_select.set_cell_data_func (cell_theme_select, (cell_layout, cell, model, iter) => {
			bool selected;
			Theme theme;
			model.get (iter, 0, out selected, 1, out theme, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
			(cell as Gtk.CellRendererToggle).sensitive = !is_restore_view || !theme.is_installed;
		});
		
		cell_theme_select.toggled.connect((path) => {
			TreeIter iter;
			ListStore model = (ListStore)tv_theme.model;
			bool selected;
			Theme theme;

			model.get_iter_from_string (out iter, path);
			model.get (iter, 0, out selected);
			model.get (iter, 1, out theme);
			model.set (iter, 0, !selected);
			theme.is_selected = !selected;
		});

		//col_theme_status ----------------------
		
		col_theme_status = new TreeViewColumn();
		//col_theme_status.title = _("");
		col_theme_status.resizable = true;
		tv_theme.append_column(col_theme_status);
		
		CellRendererPixbuf cell_theme_status = new CellRendererPixbuf ();
		col_theme_status.pack_start (cell_theme_status, false);
		col_theme_status.set_attributes(cell_theme_status, "pixbuf", 2);
		
		//col_theme_name ----------------------
		
		TreeViewColumn col_theme_name = new TreeViewColumn();
		col_theme_name.title = _("Theme");
		col_theme_name.resizable = true;
		tv_theme.append_column(col_theme_name);

		CellRendererText cell_theme_name = new CellRendererText ();
		cell_theme_name.ellipsize = Pango.EllipsizeMode.END;
		col_theme_name.pack_start (cell_theme_name, false);

		col_theme_name.set_cell_data_func (cell_theme_name, (cell_layout, cell, model, iter) => {
			Theme theme;
			model.get (iter, 1, out theme, -1);
			(cell as Gtk.CellRendererText).text = theme.name;
		});

		//col_theme_desc ----------------------
		
		TreeViewColumn col_theme_desc = new TreeViewColumn();
		col_theme_desc.title = _("Path");
		col_theme_desc.resizable = true;
		tv_theme.append_column(col_theme_desc);

		CellRendererText cell_theme_desc = new CellRendererText ();
		cell_theme_desc.ellipsize = Pango.EllipsizeMode.END;
		col_theme_desc.pack_start (cell_theme_desc, false);

		col_theme_desc.set_cell_data_func (cell_theme_desc, (cell_layout, cell, model, iter) => {
			Theme theme;
			model.get (iter, 1, out theme, -1);
			(cell as Gtk.CellRendererText).text = (theme.zip_file_path.length > 0) ? theme.zip_file_path : theme.system_path;
		});
		
		//hbox_theme_actions
		Box hbox_theme_actions = new Box (Orientation.HORIZONTAL, 6);
        vbox_theme.add (hbox_theme_actions);

		//btn_backup_theme_select_all
		btn_backup_theme_select_all = new Gtk.Button.with_label (" " + _("Select All") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_select_all, true, true, 0);
		btn_backup_theme_select_all.clicked.connect(()=>{ 
			foreach(Theme theme in theme_list_user){
				if (is_restore_view){
					if (!theme.is_installed){
						theme.is_selected = true;
					}
					else{
						//no change
					}
				}
				else{
					theme.is_selected = true;
				}
			}
			tv_theme_refresh();
		});
		
		//btn_backup_theme_select_none
		btn_backup_theme_select_none = new Gtk.Button.with_label (" " + _("Select None") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_select_none, true, true, 0);
		btn_backup_theme_select_none.clicked.connect(()=>{
			foreach(Theme theme in theme_list_user){
				if (is_restore_view){
					if (!theme.is_installed){
						theme.is_selected = false;
					}
					else{
						//no change
					}
				}
				else{
					theme.is_selected = false;
				}
			}
			tv_theme_refresh();
		});
		
		//btn_backup_theme_exec
		btn_backup_theme_exec = new Gtk.Button.with_label (" " + _("Backup") + " ");
		btn_backup_theme_exec.no_show_all = true;
		hbox_theme_actions.pack_start (btn_backup_theme_exec, true, true, 0);
		btn_backup_theme_exec.clicked.connect(btn_backup_theme_exec_clicked);

		//btn_restore_theme_exec
		btn_restore_theme_exec = new Gtk.Button.with_label (" " + _("Restore") + " ");
		btn_restore_theme_exec.no_show_all = true;
		hbox_theme_actions.pack_start (btn_restore_theme_exec, true, true, 0);
		btn_restore_theme_exec.clicked.connect(btn_restore_theme_exec_clicked);
		
		//btn_backup_theme_cancel
		btn_backup_theme_cancel = new Gtk.Button.with_label (" " + _("Cancel") + " ");
		hbox_theme_actions.pack_start (btn_backup_theme_cancel, true, true, 0);
		btn_backup_theme_cancel.clicked.connect(()=>{ 
			show_home_page();
		});
		

        //lbl_status
		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.max_width_chars = 50;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		lbl_status.no_show_all = true;
		lbl_status.visible = false;
		lbl_status.margin_bottom = 3;
		lbl_status.margin_left = 3;
		lbl_status.margin_right = 3;
		vbox_main.pack_start (lbl_status, false, true, 0);
		
		//progressbar
		progressbar = new ProgressBar();
		progressbar.no_show_all = true;
		progressbar.visible = false;
		progressbar.margin_bottom = 3;
		progressbar.margin_left = 3;
		progressbar.margin_right = 3;
		progressbar.set_size_request(-1,25);
		//progressbar.pulse_step = 0.2;
		vbox_main.pack_start (progressbar, false, true, 0);
	}
		
	private void tv_packages_refresh(){
		ListStore model = new ListStore(4, typeof(bool), typeof(Package), typeof(Gdk.Pixbuf), typeof(string));

		var pkg_list = new ArrayList<Package>();
		foreach(Package pkg in pkg_list_user.values) {
			pkg_list.add(pkg);
		}
		CompareFunc<Package> func = (a, b) => {
			return strcmp(a.name,b.name);
		};
		pkg_list.sort(func);

		//status icons
		Gdk.Pixbuf pix_installed = null;
		Gdk.Pixbuf pix_missing = null;
		Gdk.Pixbuf pix_unavailable = null;
		Gdk.Pixbuf pix_status = null;
		
		try{
			pix_installed = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-green.png");
			pix_missing = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-gray.png");
			pix_unavailable  = new Gdk.Pixbuf.from_file(App.share_dir + "/aptik/images/item-red.png");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		TreeIter iter;
		string tt = "";
		foreach(Package pkg in pkg_list) {
			//check status
			if (pkg.is_installed){
				pix_status = pix_installed;
				tt = _("Package is Installed");
			}
			else{
				if (pkg.is_available){
					pix_status = pix_missing;
					tt = _("Package is Available, Not Installed");
				}
				else{
					pix_status = pix_unavailable;
					tt = _("Package is Not Available in software repositories");
				}
			}

			//add row
			model.append(out iter);
			model.set (iter, 0, pkg.is_selected);
			model.set (iter, 1, pkg);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}
			
		tv_packages.set_model(model);
		tv_packages.columns_autosize();
	}

	private void tv_ppa_refresh(){
		ListStore model = new ListStore(4, typeof(bool), typeof(Ppa), typeof(Gdk.Pixbuf), typeof(string));
		
		//sort ppa list
		var ppa_list = new ArrayList<Ppa>();
		foreach(Ppa ppa in ppa_list_user.values) {
			ppa_list.add(ppa);
		}
		CompareFunc<Ppa> func = (a, b) => {
			return strcmp(a.name,b.name);
		};
		ppa_list.sort(func);
		
		//status icons
		Gdk.Pixbuf pix_enabled = null;
		Gdk.Pixbuf pix_missing = null;
		Gdk.Pixbuf pix_unused = null;
		Gdk.Pixbuf pix_status = null;

		try{
			pix_enabled = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-green.png");
			pix_missing = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-gray.png");
			pix_unused = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-yellow.png");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		TreeIter iter;
		string tt = "";
		foreach(Ppa ppa in ppa_list) {
			//check status
			if(ppa.is_installed){
				if (ppa.description.length > 0){
					pix_status = pix_enabled;
					tt = _("PPA is Enabled (%d installed packages)").printf(ppa.description.split(" ").length);
				}
				else{
					pix_status = pix_unused;
					tt = _("PPA is Enabled (%d installed packages)").printf(0);
				}
			}
			else{
				pix_status = pix_missing;
				tt = _("PPA is Not Added");
			}
			
			//add row
			model.append(out iter);
			model.set (iter, 0, ppa.is_selected);
			model.set (iter, 1, ppa);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}
			
		tv_ppa.set_model(model);
		tv_ppa.columns_autosize();
	}

	private void tv_theme_refresh(){
		ListStore model = new ListStore(4, typeof(bool), typeof(Theme), typeof(Gdk.Pixbuf), typeof(string));
		
		//status icons
		Gdk.Pixbuf pix_enabled = null;
		Gdk.Pixbuf pix_missing = null;
		Gdk.Pixbuf pix_status = null;

		try{
			pix_enabled = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-green.png");
			pix_missing = new Gdk.Pixbuf.from_file (App.share_dir + "/aptik/images/item-gray.png");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		TreeIter iter;
		string tt = "";
		foreach(Theme theme in theme_list_user) {
			//check status
			if(theme.is_installed){
				pix_status = pix_enabled;
				tt = _("Installed");
			}
			else{
				pix_status = pix_missing;
				tt = _("Not Installed");
			}
			
			//add row
			model.append(out iter);
			model.set (iter, 0, theme.is_selected);
			model.set (iter, 1, theme);
			model.set (iter, 2, pix_status);
			model.set (iter, 3, tt);
		}
			
		tv_theme.set_model(model);
		tv_theme.columns_autosize();
	}
	
	private bool check_backup_folder(){
		if ((App.backup_dir != null) && dir_exists (App.backup_dir)){
			return true;
		}
		else{
			string title = "Backup Directory Not Selected";
			string msg = "Please select the backup directory";
			gtk_messagebox(title, msg, this, false);
			return false;
		}
	}

	private bool check_backup_file(string file_name){
		if (check_backup_folder()){
			string backup_file = App.backup_dir + file_name;
			var f = File.new_for_path(backup_file);
			if (!f.query_exists()){
				string title = "File Not Found";
				string msg = _("File not found in backup directory") + " - %s".printf(file_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else{
				return true;
			}
		}
		else{
			return false;
		}
	}

	private bool check_backup_subfolder(string folder_name){
		if (check_backup_folder()){
			string folder = App.backup_dir + folder_name;
			var f = File.new_for_path(folder);
			if (!f.query_exists()){
				string title = "Folder Not Found";
				string msg = _("Folder not found in backup directory") + " - %s".printf(folder_name);
				gtk_messagebox(title, msg, this, true);
				return false;
			}
			else{
				return true;
			}
		}
		else{
			return false;
		}
	}

	private void btn_about_clicked (){
		var dialog = new Gtk.AboutDialog();
		dialog.set_destroy_with_parent (true);
		dialog.set_transient_for (this);
		dialog.set_modal (true);
		
		//dialog.artists = {"", ""};
		dialog.authors = {"Tony George"};
		dialog.documenters = null; 
		dialog.translator_credits = ""; 
		//dialog.add_credit_section("Sponsors", "yy");
		
		dialog.program_name = AppName;
		dialog.comments = _("System migration toolkit for Ubuntu-based distributions");
		dialog.copyright = "Copyright © 2014 Tony George (teejee2008@gmail.com)";
		dialog.version = AppVersion;
		
		try{
			dialog.logo = new Gdk.Pixbuf.from_file (App.share_dir + """/pixmaps/aptik.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.wrap_license = true;

		dialog.website = "http://teejeetech.blogspot.in";
		dialog.website_label = "http://teejeetech.in";

		dialog.response.connect ((response_id) => {
			if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
				dialog.hide_on_delete ();
			}
		});

		dialog.present ();
	}
	
	private void show_home_page(){
		notebook.page = 0;
		resize(def_width, def_height);	
		title = AppName + " v" + AppVersion;
		progress_hide();
	}
	
	/* PPA */
	
	private void btn_backup_ppa_clicked(){
		if (!check_backup_folder()) { return; }
		
		progress_begin(_("Checking installed PPAs..."));
		
		try {
			is_running = true;
			Thread.create<void> (btn_backup_ppa_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		progress_hide();
	}
	
	private void btn_backup_ppa_clicked_thread(){
		ppa_list_user = App.list_ppa();
		//un-select unused PPAs
		foreach(Ppa ppa in ppa_list_user.values){
			if (ppa.description.length == 0){
				ppa.is_selected = false;
			}
		}
		
		is_restore_view = false;
		tv_ppa_refresh();
		btn_backup_ppa_exec.visible = true;
		btn_restore_ppa_exec.visible = false;
		lbl_ppa_message.label = _("Select the PPAs to backup");
		title = "Backup Software Sources";
		notebook.page = 2;
		is_running = false;
	}
	
	private void btn_backup_ppa_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Ppa ppa in ppa_list_user.values){
			if (ppa.is_selected){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("No PPA Selected");
			string msg = _("Select the PPAs to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		gtk_set_busy(true, this);
		
		if (save_ppa_list_selected(true)){
			show_home_page();
		}
		
		gtk_set_busy(false, this);
	}
		
		
	private void btn_restore_ppa_clicked(){
		if (!check_backup_folder()) { return; }
		if (!check_backup_file("ppa.list")) { return; }
		
		progress_begin(_("Checking installed PPAs..."));
		
		try {
			is_running = true;
			Thread.create<void> (btn_restore_ppa_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		progress_hide();
	}
	
	private void btn_restore_ppa_clicked_thread(){
		ppa_list_user = App.read_ppa_list();
		is_restore_view = true;
		tv_ppa_refresh();
		btn_backup_ppa_exec.visible = false;
		btn_restore_ppa_exec.visible = true;
		lbl_ppa_message.label = _("Select the PPAs to restore");
		title = "Restore Software Sources";
		notebook.page = 2;
		is_running = false;
	}

	private void btn_restore_ppa_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Ppa ppa in ppa_list_user.values){
			if (ppa.is_selected && !ppa.is_installed){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("Nothing To Do");
			string msg = _("Selected PPAs are already enabled on this system");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		progress_begin(_("Adding PPAs..."));
		
		//save ppa.list
		string file_name = "ppa.list";
		bool is_success = save_ppa_list_selected(false);	
		if (!is_success){
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, false);
			return;
		}

		int count = 0;
		int count_total = 0;
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		string log_msg = "";
		
		//get total count
		foreach(Ppa ppa in ppa_list_user.values){
			if (ppa.is_selected && !ppa.is_installed){
				count_total++;
			}
		}
		
		//add PPAs
		foreach(Ppa ppa in ppa_list_user.values){
			if (ppa.is_selected && !ppa.is_installed){
				lbl_status.label = _("Adding PPA") + " '%s'".printf(ppa.name);
				gtk_do_events();
				
				cmd = "add-apt-repository -y ppa:%s".printf(ppa.name);
				ret_val = execute_command_script_sync(cmd,out std_out,out std_err);
				if (ret_val != 0){
					log_error(std_err);
				}
				gtk_do_events();
			}
			
			count++;
			progressbar.fraction = count / (count_total * 1.0);
			gtk_do_events();
		}
		
		progress_begin(_("Updating Package Information..."));

		App.run_apt_update();
		while(App.is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}

		string title = "Finished";
		string msg = "PPAs added successfully";
		gtk_messagebox(title, msg, this, false);
			
		show_home_page();
	}

	private bool save_ppa_list_selected(bool show_on_success){
		string file_name = "ppa.list";
		
		bool is_success = App.save_ppa_list_selected(ppa_list_user);
		
		if (is_success){
			if (show_on_success){
				string title = _("Finished");
				string msg = _("Backup created successfully") + ".\n";
				msg += _("List saved with file name") + " '%s'".printf(file_name);
				gtk_messagebox(title, msg, this, false);
			}
		}
		else{
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}	
		
		return is_success;
	}
	
	/* Packages */

	private void btn_backup_packages_clicked(){
		if (!check_backup_folder()) { return; }

		progress_begin(_("Checking installed packages..."));
		
		try {
			is_running = true;
			Thread.create<void> (btn_backup_packages_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		progress_hide();
	}
	
	private void btn_backup_packages_clicked_thread(){
		var list_manual = App.list_manual();
		var list_top = App.list_top();
		//unselect all
		foreach(Package pkg in list_top.values){
			list_top[pkg.name].is_selected = false;
		}
		//select manual
		foreach(Package pkg in list_manual.values){
			list_top[pkg.name].is_selected = true;
		}
		pkg_list_user = list_top;
		
		is_restore_view = false;
		tv_packages_refresh();
		btn_backup_packages_exec.visible = true;
		btn_restore_packages_exec.visible = false;
		lbl_packages_message.label = _("Select the packages to backup") + ". " + 
			("By default, all packages included with the distribution are unselected and extra packages installed by user are selected") + ".";
		title = "Backup Software Selections";
		
		notebook.page = 1;
		resize(650, 500);	
		is_running = false;
	}
	
	private void btn_backup_packages_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Package pkg in pkg_list_user.values){
			if (pkg.is_selected){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("No Packages Selected");
			string msg = _("Select the packages to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		gtk_set_busy(true, this);
		
		save_package_list_installed();
		if (save_package_list_selected(true)){
			show_home_page();
		}
		
		gtk_set_busy(false, this);
	}
	
	private bool save_package_list_selected(bool show_on_success){
		string file_name = "packages.list";
		
		bool is_success = App.save_package_list_selected(pkg_list_user);
		
		if (is_success){
			if (show_on_success){
				string title = _("Finished");
				string msg = _("Backup created successfully") + ".\n";
				msg += _("List saved with file name") + " '%s'".printf(file_name);
				gtk_messagebox(title, msg, this, false);
			}
		}
		else{
			string title = _("Error");
			string msg = _("Failed to write")  + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}	
		
		return is_success;
	}
	
	private bool save_package_list_installed(){
		string file_name = "packages-installed.list";
		
		bool is_success = App.save_package_list_installed(App.list_installed(false));
		
		if (!is_success){
			string title = _("Error");
			string msg = _("Failed to write") + " '%s'".printf(file_name);
			gtk_messagebox(title, msg, this, true);
		}	
		
		return is_success;
	}
	
	
	private void btn_restore_packages_clicked(){
		if (!check_backup_folder()) { return; }
		if (!check_backup_file("packages.list")) { return; }
		
		progress_begin(_("Checking installed and available packages..."));
		
		try {
			is_running = true;
			Thread.create<void> (btn_restore_packages_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		progress_hide();
	}
	
	private void btn_restore_packages_clicked_thread(){
		pkg_list_all = App.list_all();
		pkg_list_user = App.read_package_list(pkg_list_all);
		is_restore_view = true;
		tv_packages_refresh();
		btn_backup_packages_exec.visible = false;
		btn_restore_packages_exec.visible = true;
		lbl_packages_message.label = _("Select the packages to restore");
		title = "Restore Software Selections";
		notebook.page = 1;
		resize(650, 500);
		is_running = false;
	}

	private void btn_restore_packages_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Package pkg in pkg_list_user.values){
			if (pkg.is_selected && pkg.is_available && !pkg.is_installed){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("Nothing To Do");
			string msg = _("There are no packages selected for installation");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		//save packages.list
		string file_name = "packages.list";
		progress_begin(_("Saving") + " '%s'".printf(file_name));
		bool is_success = save_package_list_selected(false);	
		if (!is_success){
			progress_end(_("Failed to write")  + " '%s'".printf(file_name));
		}
		
		//check list of packages to install
		get_package_installation_summary();
		if (list_install.length == 0){
			string title = _("Nothing To Do");
			string msg = "";
			if (list_unknown.length > 0){
				msg += _("Following packages are NOT available") + ":\n\n" + list_unknown + "\n\n";
			}
			msg += _("There are no packages selected for installation");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		//show summary prompt
		var dialog = new LogWindow();
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.set_title(_("Install Summary"));
		dialog.set_log_msg(summary);
		dialog.set_prompt_msg(_("Continue with installation?"));
		dialog.show_yes_no();
		int response = dialog.run();
		dialog.destroy();

		if (response == Gtk.ResponseType.YES){
			//App.download_packages(list_install);
			//while (App.is_running){
				//update_progress("Downloading");
			//}

			progress_begin(_("Installing packages..."));
			
			iconify();
			gtk_do_events();
			
			string cmd = "apt-get install -y %s".printf(list_install);
			cmd += "\n\necho '" + _("Finished installing packages") + ".'";
			cmd += "\necho '" + _("Close window to exit...") + "'";
			cmd += "\nread dummy";
			execute_command_script_in_terminal_sync(create_temp_bash_script(cmd));
			//success/error will be displayed by apt-get in terminal
			
			deiconify();
			gtk_do_events();
		}
		
		show_home_page();
	}
	
	private void get_package_installation_summary(){
		lbl_status.label = _("Checking available packages...");
		
		try {
			is_running = true;
			Thread.create<void> (get_package_installation_summary_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
	}
	
	private void get_package_installation_summary_thread(){
		list_install = "";
		list_unknown = "";
		summary = "";

		foreach(Package pkg in pkg_list_user.values){
			if (pkg.is_selected && pkg.is_available && !pkg.is_installed){
				list_install += " %s".printf(pkg.name);
			}
		}
		foreach(Package pkg in pkg_list_user.values){
			if (pkg.is_selected && !pkg.is_available && !pkg.is_installed){
				list_unknown += " %s".printf(pkg.name);
			}
		}
		
		list_install = list_install.strip();
		list_unknown = list_unknown.strip();

		string cmd = "apt-get install -s %s".printf(list_install);
		string txt = execute_command_sync_get_output(cmd);

		summary = "";
		if (list_unknown.strip().length > 0){
			summary += ("Following packages are NOT available") + "\n";
			summary += list_unknown + "\n\n";
		}
		
		foreach(string line in txt.split("\n")){
			if (line.has_prefix("Inst ")||line.has_prefix("Conf ")||line.has_prefix("Remv ")){
				//skip
			}
			else{
				summary += line + "\n";
			}
		}
		
		is_running = false;
	}
	
	/* APT Cache */
	
	private void btn_backup_cache_clicked(){
		if (!check_backup_folder()) { return; }

		string archives_dir = App.backup_dir + "archives";
		
		progress_begin(_("Copying packages") + "...");
		
		App.backup_apt_cache();
		
		while(App.is_running){
			update_progress(_("Copying"));
		}
		
		progress_end(_("Finished"));
		
		string title = _("Finished");
		string msg = _("Packages copied successfully") + ".\n";
		msg += _("%ld packages in backup").printf(get_file_count(archives_dir));
		gtk_messagebox(title, msg, this, false);

		progress_hide();
		notebook.page = 0;
	}

	private void btn_restore_cache_clicked(){
		if (!check_backup_folder()) { return; }

		//check 'archives' directory
		string archives_dir = App.backup_dir + "archives";
		var f = File.new_for_path(archives_dir);
		if (!f.query_exists()){
			string title = _("Files Not Found");
			string msg = _("Cache backup not found in backup directory");
			gtk_messagebox(title, msg, this, true);
			return;
		}
		
		progress_begin(_("Copying packages") + "...");
		
		App.restore_apt_cache();
		while(App.is_running){
			update_progress(_("Copying"));
		}
		
		progress_end(_("Finished"));
		
		string title = _("Finished");
		string msg = _("Packages copied successfully") + ".\n";
		msg += _("%ld packages in cache").printf(get_file_count("/var/cache/apt/archives") - 2); //excluding 'lock' and 'partial'
		gtk_messagebox(title, msg, this, false);

		progress_hide();
		notebook.page = 0;
	}
	
	private void update_progress(string message){
		progressbar.fraction = App.progress_count / (App.progress_total * 1.0);
		lbl_status.label = message + ": %s".printf(App.status_line);
		gtk_do_events();
		Thread.usleep ((ulong) 0.1 * 1000000);
	}
	
	/* Themes */
	
	private void btn_backup_theme_clicked(){
		progress_hide();
				
		if (!check_backup_folder()) { return; }

		gtk_set_busy(true, this);
		
		is_restore_view = false;
		theme_list_user = App.list_all_themes();
		tv_theme_refresh();
		btn_backup_theme_exec.visible = true;
		btn_restore_theme_exec.visible = false;
		lbl_theme_message.label = _("Select the themes to backup");
		title = "Backup Themes";
		notebook.page = 3;
		
		gtk_set_busy(false, this);
	}
	
	private void btn_backup_theme_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("No Themes Selected");
			string msg = _("Select the themes to backup");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		progress_begin(_("Archiving themes") + "...");
		
		//get total file count
		App.progress_total = 0;
		App.progress_count = 0;
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected){
				App.progress_total += (int) get_file_count(theme.system_path);
			}
		}

		//zip themes
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected){
				App.zip_theme(theme);
				while(App.is_running){
					update_progress(_("Archiving"));
				}
			}
		}

		string title = _("Finished");
		string msg = _("Backups created successfully");
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}

	private void btn_restore_theme_clicked(){
		progress_hide();

		gtk_set_busy(true, this);
		
		if (check_backup_subfolder("themes") || check_backup_subfolder("icons") ){
			is_restore_view = true;
			theme_list_user = App.get_all_themes_from_backup();
			tv_theme_refresh();
			btn_backup_theme_exec.visible = false;
			btn_restore_theme_exec.visible = true;
			lbl_theme_message.label = _("Select the themes to restore");
			title = "Restore Themes";
			notebook.page = 3;
		}
		
		gtk_set_busy(false, this);
	}

	private void btn_restore_theme_exec_clicked(){
		//check if no action required
		bool none_selected = true;
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected && !theme.is_installed){
				none_selected = false;
				break;
			}
		}
		if (none_selected){
			string title = _("Nothing To Do");
			string msg = _("Selected themes are already installed");
			gtk_messagebox(title, msg, this, false);
			return;
		}
		
		progress_begin(_("Extracting themes") + "...");

		//get total file count
		App.progress_total = 0;
		App.progress_count = 0;
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected && !theme.is_installed){
				string cmd = "tar -tvf '%s'".printf(theme.zip_file_path);
				string txt = execute_command_sync_get_output(cmd);
				App.progress_total += txt.split("\n").length;
			}
		}
		
		//unzip themes
		foreach(Theme theme in theme_list_user){
			if (theme.is_selected && !theme.is_installed){
				App.unzip_theme(theme);
				while(App.is_running){
					update_progress(_("Extracting"));
				}
				App.update_permissions(theme.system_path);
			}
		}

		string title = _("Finished");
		string msg = _("Themes restored successfully");
		gtk_messagebox(title, msg, this, false);

		show_home_page();
	}
	
	/* Misc */
	
	private void btn_take_ownership_clicked(){
		progress_hide();

		string title = _("Change Ownership");
		string msg = _("Owner will be changed to '%s' (uid=%d) for files in directory '%s'").printf(App.user_login,App.user_uid,App.user_home);
		msg += "\n\n" + _("Continue?");
		
		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, msg);
		dlg.set_title(title);
		dlg.set_default_size (200, -1);
		dlg.set_transient_for(this);
		dlg.set_modal(true);
		int response = dlg.run();
		dlg.destroy();
		gtk_do_events();
		
		if (response == Gtk.ResponseType.YES){
			gtk_set_busy(true,this);
			
			bool is_success = App.take_ownership();
			if (is_success) {
				title = _("Success");
				msg = _("You are now the owner of all files in your home directory");
				gtk_messagebox(title, msg, this, false);
			}
			else{
				title = _("Error");
				msg = _("Failed to change file ownership");
				gtk_messagebox(title, msg, this, true);
			}
			
			gtk_set_busy(false,this);
		}
	}

	private void progress_begin(string message = ""){
		btn_about.visible = false;
		lbl_status.visible = true;
		progressbar.visible = true;
		progressbar.fraction = 0.0;
		lbl_status.label = message;
		notebook.sensitive = false;
		gtk_set_busy(true, this);
		gtk_do_events();
	}
	
	private void progress_hide(string message = ""){
		btn_about.visible = true;
		lbl_status.visible = false;
		progressbar.visible = false;
		progressbar.fraction = 0.0;
		lbl_status.label = message;
		notebook.sensitive = true;
		gtk_set_busy(false, this);
		gtk_do_events();
	}
	
	private void progress_end(string message = ""){
		btn_about.visible = false;
		lbl_status.visible = true;
		progressbar.visible = true;
		progressbar.fraction = 1.0;
		lbl_status.label = message;
		notebook.sensitive = true;
		gtk_set_busy(false, this);
		gtk_do_events();
	}

}