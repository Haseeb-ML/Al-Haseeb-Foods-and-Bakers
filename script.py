import os

files = [
    r'c:\erp\lib\screens\shared\customer_list_screen.dart',
    r'c:\erp\lib\screens\shared\expense_list_screen.dart',
    r'c:\erp\lib\screens\shared\new_sale_screen.dart',
    r'c:\erp\lib\screens\admin\theme_settings_screen.dart',
    r'c:\erp\lib\screens\admin\staff_management_screen.dart',
    r'c:\erp\lib\screens\admin\backup_restore_screen.dart',
    r'c:\erp\lib\screens\admin\financial_reports_screen.dart'
]

drawer_map = {
    'customer_list_screen.dart': 'const Drawer(width: 230, child: AdminSidebar(currentRoute: "Customers"))',
    'expense_list_screen.dart': 'sidebarUser.isAdmin ? Drawer(width: 230, child: AdminSidebar(currentRoute: "Expenses", user: sidebarUser)) : Drawer(width: 230, child: StaffSidebar(currentRoute: "Expenses", user: sidebarUser))',
    'new_sale_screen.dart': 'widget.isAdmin ? const Drawer(width: 230, child: AdminSidebar(currentRoute: "New Sale")) : Drawer(width: 230, child: StaffSidebar(currentRoute: "New Sale", user: UserModel(uid: widget.currentUserUid, name: AuthService().currentUser?.displayName ?? "Staff", email: AuthService().currentUser?.email ?? "", role: "staff", phone: "", createdAt: DateTime.now())))',
    'theme_settings_screen.dart': 'const Drawer(width: 230, child: AdminSidebar(currentRoute: "App Appearance"))',
    'staff_management_screen.dart': 'const Drawer(width: 230, child: AdminSidebar(currentRoute: "Staff"))',
    'backup_restore_screen.dart': 'const Drawer(width: 230, child: AdminSidebar(currentRoute: "Backup"))',
    'financial_reports_screen.dart': 'const Drawer(width: 230, child: AdminSidebar(currentRoute: "Profit & Loss"))',
}

for fp in files:
    if not os.path.exists(fp):
        continue
    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    
    fname = os.path.basename(fp)
    drawer_widget = drawer_map.get(fname, '')

    # 1. Modify Scaffold
    if "return Scaffold(\n                  backgroundColor: bg,\n                  body: SafeArea(" in content:
        content = content.replace(
            "return Scaffold(\n                  backgroundColor: bg,\n                  body: SafeArea(",
            f"return Scaffold(\n                  backgroundColor: bg,\n                  drawer: {drawer_widget},\n                  body: SafeArea("
        )
    elif "return Scaffold(\n              backgroundColor: bg,\n              body: SafeArea(" in content:
        content = content.replace(
            "return Scaffold(\n              backgroundColor: bg,\n              body: SafeArea(",
            f"return Scaffold(\n              backgroundColor: bg,\n              drawer: {drawer_widget},\n              body: SafeArea("
        )
    elif "return Scaffold(\n                backgroundColor: bg,\n                body: SafeArea(" in content:
        content = content.replace(
            "return Scaffold(\n                backgroundColor: bg,\n                body: SafeArea(",
            f"return Scaffold(\n                backgroundColor: bg,\n                drawer: {drawer_widget},\n                body: SafeArea("
        )
        
    if fname == "financial_reports_screen.dart":
        # Uses AppBar
        content = content.replace(
            "return Scaffold(\n                  backgroundColor: bg,\n                  appBar: AppBar(",
            f"return Scaffold(\n                  backgroundColor: bg,\n                  drawer: {drawer_widget},\n                  appBar: AppBar("
        )

    # 2. Modify gesture detector
    search_str = """GestureDetector(
                        onTap: () => Navigator.pop(context),"""
    replace_str = """Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),"""
                          
    search_str_icon = "Icon(Icons.arrow_back, size: 18, color: textPrimary),"
    replace_str_icon = "Icon(Icons.menu, size: 20, color: textPrimary),"
    
    # some files have 10 spaces indentation, some have 24, so lets do simple replaces
    
    # Actually, we can use regex
    import re
    
    # Replace Navigator.pop
    content = re.sub(
        r'if \(!isDesktop( \|\| !isAdmin)?\)\s*GestureDetector\(\s*onTap: \(\) => Navigator\.pop\(context\),',
        lambda m: f'if (!isDesktop{m.group(1) or ""})\n                      Builder(\n                        builder: (context) => GestureDetector(\n                          onTap: () => Scaffold.of(context).openDrawer(),',
        content
    )
    
    # Replace the matching arrow_back right after
    # But ONLY for the drawer button we just changed.
    # To be safe, just replace arrow_back with menu if we know it's the drawer.
    # We can do this safely because arrow_back size 18 color textPrimary is very specific to this header.
    content = content.replace(
        "Icon(Icons.arrow_back, size: 18, color: textPrimary),",
        "Icon(Icons.menu, size: 20, color: textPrimary),\n                        ),"
    )

    with open(fp, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated", fname)
