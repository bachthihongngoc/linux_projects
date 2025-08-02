#!/bin/bash
if ! command -v dialog &> /dev/null; then
    echo "Dialog chưa được cài đặt. Vui lòng cài đặt dialog trước khi chạy script này."
    exit 1
fi

show_cpu_info() {
    while true; do
        mpstat 1 1> /tmp/cpu_info.txt & pid=$!
        dialog --title "Thong tin CPU" --tailbox /tmp/cpu_info.txt 20 60 --keep-window
        sleep 1
        dialog --clear --yesno "Quay lai menu chinh?" 10 30
        response=$?
        if [ $response -eq 0 ]; then
            break
        fi
    done
    rm /tmp/cpu_info.txt
}


show_memory_info() {
   while true; do
        free -h> /tmp/memory_info.txt & pid=$!
        dialog --title "Thong tin Memory" --tailbox /tmp/memory_info.txt 20 60 --keep-window
        sleep 1
        dialog --clear --yesno "Quay lai menu chinh?" 10 30
        response=$?
        if [ $response -eq 0 ]; then
            break
        fi
    done
    rm /tmp/memory_info.txt
}


show_network_info() {
    while true; do
        # Xóa nội dung cũ của file /tmp/network_info.txt
        > /tmp/network_info.txt

        # Vòng lặp để liên tục ghi dữ liệu mới nhất vào file /tmp/network_info.txt
        while true; do
            sar -n DEV 1 1 | awk '
                BEGIN {
                    print "Thoi gian         Interface   rxkB/s   txkB/s"
                    print "=================================================="
                }
                {
                    if ($1 ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) {
                        print $1, "      ", $2, "    ", $5, "    ", $6
                    }
                }
            ' >> /tmp/network_info.txt

            # Đợi 1 giây trước khi lấy dữ liệu tiếp theo
            sleep 1
        done &
        pid=$!

        # Hiển thị thông tin trong cửa sổ dialog, cập nhật dữ liệu realtime
        dialog --title "Thong tin Network" --tailbox /tmp/network_info.txt 20 60 --keep-window
        sleep 1
        # Hỏi người dùng có muốn quay lại menu chính không
        dialog --clear --yesno "Quay lai menu chinh?" 10 30
        response=$?
        if [ $response -eq 0 ]; then
            break
        fi
    done
}


show_disk_info() {
    disk_info=$(df -h)
    dialog --title "Thong tin Disk" --msgbox "$disk_info" 20 60
}


show_etc_info() {
    etc_info=$(ls -l /etc)
    dialog --title "Thong tin /etc" --msgbox "$etc_info" 20 60
}


show_processes_info() {
    # Tạo file tạm để lưu trữ dữ liệu tiến trình
    temp_file="/tmp/processes_info.txt"

    while true; do
        # Xóa nội dung cũ của file tạm
        > "$temp_file"

        # Sử dụng lệnh ps để lấy thông tin về các tiến trình
        ps aux --sort=-%cpu | head -n 20 > "$temp_file"

        # Hiển thị thông tin từ file tạm trong cửa sổ dialog, cập nhật dữ liệu realtime
        dialog --title "Thong tin CPU" --tailbox "$temp_file" 20 60 --keep-window
	# Đợi một khoảng thời gian ngắn trước khi lấy dữ liệu tiến trình tiếp theo
        sleep 1

        # Hỏi người dùng có muốn quay lại menu chính không
        dialog --clear --yesno "Quay lai menu chinh?" 10 30
        response=$?
        if [ $response -eq 0 ]; then
            break
        fi
    done

    # Xóa file tạm khi kết thúc hàm
    rm "$temp_file"
}



show_system_info() {
    system_info=$(uname -a)
    dialog --title "Thong tin he thong" --msgbox "$system_info" 20 60
}


while true; do
    choice=$(dialog --clear --backtitle "Quan Ly He Thong" --title "Menu Quan Ly He Thong" \
        --menu "Lua chon cua ban:" 20 60 10 \
        1 "Xem thong tin CPU" \
        2 "Xem thong tin Memory" \
        3 "Xem thong tin Network" \
        4 "Xem thong tin Disk" \
        5 "Xem thong tin /etc" \
        6 "Danh sach tien trinh dang chay" \
        7 "Thong tin he thong" \
        8 "Thoat" \
        3>&1 1>&2 2>&3)

    case $choice in
        1)
            show_cpu_info
            ;;
        2)
            show_memory_info
            ;;
        3)
            show_network_info
            ;;
        4)
            show_disk_info
            ;;
        5)
            show_etc_info
            ;;
        6)
            show_processes_info
            ;;
        7)
            show_system_info
            ;;
        8)
            break
            ;;
        *)
            dialog --title "Loi" --msgbox "Lua chon khong hop le. Vui long chon lai." 10 30
            ;;
    esac
done

clear
echo "Thoat chuong trinh."
