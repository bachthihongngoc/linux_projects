#!/bin/bash

# Kiem tra va cai dat dialof neu chua co 
if ! command -v dialog &>/dev/null; then
    echo "Dialog not installed. Installing..."
    sudo apt install dialog -y
fi

# Ham them nguoi dung
add_user() {
    username=$(dialog --inputbox "Enter username:" 8 40 --output-fd 1)
    password=$(dialog --passwordbox "Enter password:" 8 40 --output-fd 1)

    if [ -z "$username" ]; then
        dialog --msgbox "Username cannot be empty!" 6 40
        return
    fi

    # chay lenh useradd neu co
    error_message=$(sudo useradd -m -s /bin/bash "$username" 2>&1)

    if [ $? -eq 0 ]; then
        echo "$username:$password" | sudo chpasswd
        dialog --msgbox "User $username has been created successfully" 6 40
    else
        dialog --msgbox "Error creating user: $error_message" 10 50
    fi
}


# Ham xoa nguoi dung
remove_user() {
    username=$(dialog --inputbox "Enter the username to delete:" 8 40 --output-fd 1)
    
    if [ -z "$username" ]; then
        dialog --msgbox "Username cannot be empty!" 6 40
        return
    fi
    
    if ! id "$username" &>/dev/null; then
        dialog --msgbox "User $username does not exist!" 6 40
        return
    fi

    # Kiem tra va dung tat ca tien trinh cua user truoc khi xoa
    sudo pkill -u "$username"

    # Xoa user voi quyen root
    if sudo userdel -r "$username"; then
        dialog --msgbox "User $username was successfully deleted!" 6 40
    else
        dialog --msgbox "Error deleting user $username! Please check the progress and try again." 8 50
    fi
}


# Ham cap nhat nguoi dung
update_user() {
    username=$(dialog --inputbox "Enter the username to update:" 8 40 --output-fd 1)
    
    # Kiem tra user co ton tai khong
    if ! id "$username" &>/dev/null; then
        dialog --msgbox "User $username does not exist!" 6 40
        return
    fi

    new_username=$(dialog --inputbox "Enter new name (leave blank if not changed):" 8 40 --output-fd 1)
    new_password=$(dialog --passwordbox "Enter new password (leave blank if not changed):" 8 40 --output-fd 1)

    # Neu co doi username
    if [ -n "$new_username" ] && [ "$new_username" != "$username" ]; then
        sudo usermod -l "$new_username" "$username" 2>/tmp/usermod_error
        if [ $? -ne 0 ]; then
            error_msg=$(cat /tmp/usermod_error)
            dialog --msgbox "Error when renaming: $error_msg" 10 50
            return
        fi
        username="$new_username"
    fi

    # Neu co doi mat khau
    if [ -n "$new_password" ]; then
        echo "$username:$new_password" | sudo chpasswd
    fi

    dialog --msgbox "User $username has been updated." 6 40
}


# Ham chinh sua quyen
modify_permissions() {
    filepath=$(dialog --inputbox "Enter file/folder path:" 8 40 --output-fd 1)
    
    if [ ! -e "$filepath" ]; then
        dialog --msgbox "Error: File/folder does not exist!" 6 40
        return
    fi
    
    new_owner=$(dialog --inputbox "Enter new owner (leave blank if not changed):" 8 40 --output-fd 1)
    new_permissions=$(dialog --inputbox "Enter new permissions (leave blank if not changed):" 8 40 --output-fd 1)
    
    if [ -n "$new_owner" ]; then
        if sudo chown "$new_owner" "$filepath" 2>/tmp/perm_error; then
            dialog --msgbox "The owner of $filepath has been changed to $new_owner." 10 60
        else
            error_msg=$(cat /tmp/perm_error)
            dialog --msgbox "Error changing owner: $error_msg" 8 50
        fi
    fi
    
    if [ -n "$new_permissions" ]; then
        if sudo chmod "$new_permissions" "$filepath" 2>/tmp/perm_error; then
            dialog --msgbox "The permissions of $filepath have been changed to $new_permissions." 10 60
        else
            error_msg=$(cat /tmp/perm_error)
            dialog --msgbox "Error changing permissions: $error_msg" 8 50
        fi
    fi
}

# Ham hien thi danh sach nguoi dung
list_users() {
    users=$(cut -d: -f1 /etc/passwd | paste -d '\n' -s) 
    dialog --msgbox "List of users:\n\n$users" 20 50
}




# Ham xem thong tin nguoi dung
view_user_info() {
    username=$(dialog --inputbox "Enter username to view information:" 8 40 --output-fd 1)
    if id "$username" &>/dev/null; then
        info=$(id "$username"; grep "^$username:" /etc/passwd)
        dialog --msgbox "User information:\n\n$info" 20 50
    else
        dialog --msgbox "User $username does not exist." 6 40
    fi
}

# Ham kiem tra quyen truy cap cua nguoi dung doi voi tep/thu muc
check_user_permissions() {
    username=$(dialog --inputbox "Enter username:" 8 40 --output-fd 1)
    filepath=$(dialog --inputbox "Enter file/folder path:" 8 40 --output-fd 1)

    if [ -e "$filepath" ]; then
        owner=$(ls -ld "$filepath" | awk '{print $3}')
        permissions="Owner: $owner\n\n$username's access rights to $filepath:\n"
        [ -r "$filepath" ] && permissions+="[✔] Have read permission\n" || permissions+="[ ] No read permission\n"
        [ -w "$filepath" ] && permissions+="[✔] Have write permission\n" || permissions+="[ ] No write permission\n"
        [ -x "$filepath" ] && permissions+="[✔] Execute\n" || permissions+="[ ] No execute\n"
        dialog --msgbox "$permissions" 20 70
    else
        dialog --msgbox "File/folder does not exist." 6 40
    fi
}



# Ham hien thi menu 
main_menu() {
    while true; do
        choice=$(dialog --menu "User Management" 15 50 7 \
            1 "Add User" \
            2 "Delete User" \
            3 "Update User Information" \
            4 "View User List" \
            5 "View User Information" \
            6 "Edit Access Rights" \
            7 "Check Access Rights" \
            0 "Exit" --output-fd 1)

        # Neu chon Cancel,ESC, hoac chon "0", thoat chuong trinh
        if [ -z "$choice" ] || [ "$choice" -eq 0 ]; then
            clear
            echo "You have exited the program!"
            exit 0
        fi

        case $choice in
            1) add_user ;;
            2) remove_user ;;
            3) update_user ;;
            4) list_users ;;
            5) view_user_info ;;
            6) modify_permissions ;;
            7) check_user_permissions ;;
            *) dialog --msgbox "Invalid selection!" 6 40 ;;
        esac
    done
}

# Chay menu chinh
main_menu

