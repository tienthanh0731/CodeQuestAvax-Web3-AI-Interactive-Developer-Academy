# TÀI LIỆU CHUYÊN SÂU 03: BẢO MẬT SMART CONTRACT & PHÒNG CHỐNG DRAINER
**Nguồn tổng hợp:** OWASP Smart Contract Top 10, ConsenSys Smart Contract Best Practices, Cyfrin Updraft Security Courses.

---

## 1. Top 10 Lỗ Hổng Bảo Mật Smart Contract Theo Chuẩn OWASP

1. **Access Control (Lỗ hổng phân quyền):** Thiếu modifier `onlyOwner` hoặc kiểm tra quyền lỏng lẻo ở các hàm quan trọng (`mint`, `setFee`, `pause`), cho phép bất kỳ ai cũng có thể chiếm quyền quản trị.
2. **Reentrancy (Tấn công tái nhập):** Gọi hàm chuyển tiền ra bên ngoài trước khi cập nhật số dư, cho phép attacker rút tiền theo vòng lặp vô hạn.
3. **Price Oracle Manipulation (Thao túng giá Oracle):** Sử dụng giá từ các cặp thanh khoản AMM (như Uniswap v2) dễ bị bóp méo giá bằng các khoản vay nhanh (Flash Loan).
4. **Input Validation (Thiếu kiểm tra đầu vào):** Chấp nhận dữ liệu sai lệch hoặc địa chỉ `address(0)`.
5. **Unchecked External Calls (Không kiểm tra kết quả gọi hàm ngoài):** Sử dụng `.call` nhưng không kiểm tra biến `bool success`.
6. **Integer Overflow/Underflow:** Tràn số nguyên trong các khối `unchecked` hoặc Solidity cũ.
7. **Insecure Randomness (Tạo số ngẫu nhiên không an toàn):** Sử dụng các biến on-chain dự đoán được như `block.timestamp`, `block.prevrandao`. Kẻ tấn công hoặc validator có thể dự đoán trước kết quả xổ số.
8. **Denial of Service (DoS):** Duyệt mảng (Loop) không có giới hạn độ dài khiến transaction vượt quá gas limit của block hoặc bị hacker cố tình làm revert.
9. **Signature Replay & Phishing:** Tái sử dụng chữ ký off-chain khi thiếu nonce hoặc chainId (EIP-712).
10. **Front-running / MEV:** Bị bot kẹp lệnh (Sandwich attack) khi giao dịch trên mempool công khai.

---

## 2. Giải Phẫu Chi Tiết: Reentrancy Attack & Quy Tắc CEI

### 2.1. Mã Nguồn Chứa Lỗ Hổng (Vulnerable Code):
```solidity
// ❌ CỰC KỲ NGUY HIỂM:
function withdraw() public {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "No funds");

    // BƯỚC 1: Chuyển tiền ra ngoài TRƯỚC
    (bool sent, ) = msg.sender.call{value: balance}("");
    require(sent, "Failed to send Ether");

    // BƯỚC 2: Trừ số dư SAU
    balances[msg.sender] = 0; 
}
```

### Kịch Bản Tấn Công:
1. Attacker tạo contract có hàm `receive()`:
```solidity
receive() external payable {
    if (address(victimVault).balance >= 1 ether) {
        victimVault.withdraw(); // Tái nhập vào hàm withdraw trước khi dòng "balances[msg.sender] = 0" chạy!
    }
}
```
2. Kết quả: Toàn bộ số dư của Vault bị rút cạn sạch.

### 2.2. Giải Pháp 1: Quy Tắc Checks-Effects-Interactions (CEI)
Luôn luôn tuân thủ thứ tự:
1. **Checks:** Kiểm tra điều kiện (`require(balance > 0)`).
2. **Effects:** Thay đổi số dư nội bộ trước (`balances[msg.sender] = 0`).
3. **Interactions:** Gửi tiền ra ngoài ở bước cuối cùng.

```solidity
// ✅ AN TOÀN TUYỆT ĐỐI:
function withdraw() public {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "No funds");

    // 1. Effects TRƯỚC:
    balances[msg.sender] = 0; 

    // 2. Interactions SAU:
    (bool sent, ) = msg.sender.call{value: balance}("");
    require(sent, "Failed to send Ether");
}
```

### 2.3. Giải Pháp 2: Mutex Lock (ReentrancyGuard)
```solidity
abstract contract ReentrancyGuard {
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
```

---

## 3. Các Chiêu Trò "Wallet Drainer" Nguy Hiểm Nhất Hiện Nay

1. **Lạm Dụng `approve(spender, type(uint256).max)`:**
   - Người dùng click vào link nhận Airdrop hoặc Mint NFT giả mạo trên Telegram/X.
   - Trang web yêu cầu ký lệnh `approve` với số tiền vô hạn (`0xffffff...`).
   - Ngay sau khi ký, bot của hacker chạy ngầm lệnh `transferFrom` gom sạch token USDC/USDT trong ví của nạn nhân về ví kẻ cắp.
2. **Lạm Dụng `setApprovalForAll(operator, true)`:**
   - Tương tự như trên nhưng nhắm vào chuẩn NFT (ERC-721). Khi nạn nhân ký lệnh này, kẻ xấu có toàn quyền chuyển nhượng mọi NFT trong ví sang tài khoản của chúng mà không cần hỏi lại.
3. **Permit Phishing (EIP-2612 & EIP-712):**
   - Kẻ lừa đảo yêu cầu ký một tin nhắn gasless (không tốn gas). Người dùng tưởng là đăng nhập vô hại, nhưng bản chất là chữ ký cấp quyền chi tiêu token.
