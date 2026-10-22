# TÀI LIỆU CHUYÊN SÂU 02: SOLIDITY 0.8+ VÀ CHUẨN TOKEN ERC-20 / SOULBOUND (SBT)
**Nguồn tổng hợp:** Solidity by Example, OpenZeppelin Contracts Documentation, EIP-20 & EIP-5192.

---

## 1. Các Tính Năng Cốt Lõi Của Solidity Hiện Đại (>= 0.8.20)

### 1.1. Tự Động Kiểm Tra Tràn Số (Checked Arithmetic)
Trước phiên bản 0.8.0, lập trình viên bắt buộc phải dùng thư viện `SafeMath` của OpenZeppelin để tránh lỗi tràn số (Overflow/Underflow):
```solidity
// Trước 0.8:
uint8 x = 255;
x = x + 1; // x biến thành 0 mà không báo lỗi!
```
Từ Solidity 0.8.0 trở lên, trình biên dịch tự động revert giao dịch nếu phát hiện tràn số mà không cần `SafeMath`. Nếu muốn bỏ qua kiểm tra để tiết kiệm gas cho các phép toán chắc chắn an toàn (như vòng lặp `for (uint256 i; i < len; ++i)`), ta dùng khối `unchecked { ... }`.

### 1.2. Custom Errors Tiết Kiệm Gas Vượt Trội
Thay vì dùng `require(condition, "Chuỗi thông báo lỗi rất dài tốn gas")`, chuẩn hiện đại là dùng `error`:
```solidity
error InsufficientBalance(uint256 available, uint256 required);

function transfer(address to, uint256 amount) external {
    if (balanceOf[msg.sender] < amount) {
        revert InsufficientBalance(balanceOf[msg.sender], amount);
    }
    // ...
}
```
Custom Error chỉ tốn 4 bytes selector thay vì phải lưu toàn bộ chuỗi ký tự string vào calldata, giúp tiết kiệm hàng ngàn gas mỗi transaction.

### 1.3. Mô Hình Bộ Nhớ EVM: Storage vs Memory vs Calldata
- **Storage:** Lưu trữ vĩnh viễn trên blockchain (đắt nhất). Dùng cho các biến trạng thái (State variables) như `mapping(address => uint256) public balanceOf`.
- **Memory:** Bộ nhớ tạm thời, tồn tại trong quá trình thực thi hàm và bị hủy khi hàm kết thúc. Cho phép chỉnh sửa (mutable).
- **Calldata:** Vùng nhớ chỉ đọc (read-only), không thể chỉnh sửa, nhận trực tiếp tham số truyền vào từ transaction. Rẻ hơn `memory` rất nhiều. Luôn ưu tiên dùng `calldata` cho các tham số kiểu `string` hoặc mảng `bytes` trong hàm `external`.

---

## 2. Tiêu Chuẩn Token ERC-20 Hoàn Chỉnh (EIP-20)
Mọi token có thể thay thế (Fungible Token) đều phải triển khai interface sau:

```solidity
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
```

### Triển Khai Thực Chiến Chuẩn Mực:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        uint256 supplyWithDecimals = initialSupply * (10 ** 18);
        totalSupply = supplyWithDecimals;
        balanceOf[msg.sender] = supplyWithDecimals;
        emit Transfer(address(0), msg.sender, supplyWithDecimals);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
```

---

## 3. Mẫu Thiết Kế Soulbound Token (SBT - Non-Transferable Token)
Soulbound Token là NFT gắn liền với một danh tính (địa chỉ ví) duy nhất và **không thể chuyển nhượng hoặc bán lại** (rất phù hợp để làm chứng chỉ tốt nghiệp, huy hiệu kỹ năng, bằng cấp).

### Cơ Chế Khóa Chuyển Nhượng Trong Solidity:
Chỉ cần ghi đè (override) các hàm chuyển tiền chuẩn (`transferFrom`, `safeTransferFrom`) và ép `revert`:
```solidity
function transferFrom(address, address, uint256) external pure {
    revert("Soulbound: Transfer disabled");
}

function safeTransferFrom(address, address, uint256) external pure {
    revert("Soulbound: Transfer disabled");
}
```
Nhờ cơ chế này, chứng chỉ học tập trên CodeQuestAvax chỉ thuộc về chính học viên đã học và nộp bài thật, không ai có thể mua bán hay mạo danh!
