#!/bin/sh

# Kiểm tra và cài đặt Rust nếu chưa có
rustc --version || curl https://sh.rustup.rs -sSf | sh
NEXUS_HOME=$HOME/.nexus

# Yêu cầu người dùng đồng ý với điều khoản sử dụng
while [ -z "$NONINTERACTIVE" ]; do
    read -p "Do you agree to the Nexus Beta Terms of Use (https://nexus.xyz/terms-of-use)? (Y/n) " yn </dev/tty
    case $yn in
        [Nn]* ) exit;;
        [Yy]* ) break;;
        "" ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Kiểm tra Git, nếu không có thì thoát
git --version 2>&1 >/dev/null
if [ $? != 0 ]; then
  echo "Unable to find git. Please install it and try again."
  exit 1;
fi

# Hàm để cập nhật hoặc clone dự án
update_or_clone() {
  if [ -d "$NEXUS_HOME/network-api" ]; then
    echo "$NEXUS_HOME/network-api exists. Updating."
    (cd $NEXUS_HOME/network-api && git pull)
  else
    mkdir -p $NEXUS_HOME
    (cd $NEXUS_HOME && git clone https://github.com/nexus-xyz/network-api)
  fi
}

# Vòng lặp để thử lại nếu lỗi
while true; do
  update_or_clone

  echo "Starting Nexus CLI..."
  
  # Chạy ứng dụng với Cargo
  (cd $NEXUS_HOME/network-api/clients/cli && cargo run --release --bin prover -- beta.orchestrator.nexus.xyz)

  if [ $? -eq 0 ]; then
    echo "Nexus CLI ran successfully!"
    break  # Thoát vòng lặp nếu chạy thành công
  else
    echo "Nexus CLI crashed or failed. Retrying in 5 seconds..."
    sleep 5  # Đợi 5 giây trước khi thử lại
  fi
done
