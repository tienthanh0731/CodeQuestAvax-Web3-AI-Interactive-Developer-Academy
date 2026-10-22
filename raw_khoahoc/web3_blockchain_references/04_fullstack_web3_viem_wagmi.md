# TÀI LIỆU CHUYÊN SÂU 04: FULLSTACK DAPP VỚI NEXT.JS, WAGMI VÀ VIEM
**Nguồn tổng hợp:** Viem Documentation, Wagmi Documentation, Avalanche C-Chain Developer Guides.

---

## 1. Viem — Thư Viện Tương Tác Blockchain Thế Hệ Mới
Viem là thư viện TypeScript mã nguồn mở chuẩn mực, được tối ưu hóa cho EVM và nhẹ hơn Ethers.js gấp 4 lần.

### 1.1. Khởi Tạo Public Client Đọc Dữ Liệu:
```typescript
import { createPublicClient, http } from 'viem';
import { avalancheFuji } from 'viem/chains';

export const publicClient = createPublicClient({
  chain: avalancheFuji,
  transport: http('https://api.avax-test.network/ext/bc/C/rpc'),
});

// Đọc số dư ví
const balanceWei = await publicClient.getBalance({
  address: '0x87cdb5077F49888BAd48F5030A65F236FA85a48B',
});

// Đọc hàm view từ Smart Contract
const tokenName = await publicClient.readContract({
  address: '0x1234...',
  abi: ERC20_ABI,
  functionName: 'name',
});
```

### 1.2. Khởi Tạo Wallet Client Để Ký Giao Dịch:
```typescript
import { createWalletClient, custom } from 'viem';
import { avalancheFuji } from 'viem/chains';

// Kết nối với ví trình duyệt (Core Wallet / MetaMask)
export const walletClient = createWalletClient({
  chain: avalancheFuji,
  transport: custom(window.ethereum),
});
```

---

## 2. Wagmi — React Hooks Chuẩn Mực Cho DApp
Wagmi cung cấp bộ hooks giúp quản lý trạng thái kết nối ví và gửi giao dịch cực kỳ mượt mà.

### 2.1. Quản Lý Kết Nối Ví (`useAccount`, `useConnect`, `useDisconnect`):
```tsx
import { useAccount, useConnect, useDisconnect } from 'wagmi';

export function WalletButton() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected) {
    return (
      <div>
        <span>Ví: {address?.slice(0, 6)}...{address?.slice(-4)}</span>
        <button onClick={() => disconnect()}>Đăng Xuất</button>
      </div>
    );
  }

  return (
    <button onClick={() => connect({ connector: connectors[0] })} disabled={isPending}>
      {isPending ? 'Đang mở ví...' : 'Kết Nối Core Wallet / MetaMask'}
    </button>
  );
}
```

### 2.2. Gửi Giao Dịch & Theo Dõi Trạng Thái (`useWriteContract` + `useWaitForTransactionReceipt`):
```tsx
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';

export function SendTokenButton({ tokenAddress, recipient, amount }: any) {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const handleSend = () => {
    writeContract({
      address: tokenAddress,
      abi: ERC20_ABI,
      functionName: 'transfer',
      args: [recipient, parseEther(amount)],
    });
  };

  return (
    <div>
      <button onClick={handleSend} disabled={isPending || isConfirming}>
        {isPending ? 'Đang ký trên ví...' : isConfirming ? 'Đang xác nhận khối...' : 'Chuyển Token'}
      </button>

      {isSuccess && hash && (
        <a 
          href={`https://testnet.snowscan.xyz/tx/${hash}`} 
          target="_blank" 
          rel="noreferrer"
        >
          Xem biên lai trên Snowscan Fuji
        </a>
      )}
    </div>
  );
}
```

---

## 3. Xử Lý Các Lỗi Thường Gặp (Error Handling)
1. **Lỗi Từ Chối Ký (User Rejected Request):**
   - Khi người dùng bấm "Reject/Cancel" trên ví, EVM trả về mã lỗi `code: 4001`. Cần bắt lỗi này và thông báo nhẹ nhàng: *"Bạn đã hủy yêu cầu ký trên ví"*.
2. **Lỗi Không Đủ Gas (Insufficient Funds):**
   - Cần hướng dẫn người dùng nhận AVAX miễn phí tại [faucet.avax.network](https://faucet.avax.network/).
3. **Lỗi Lệch Chain (Wrong Network):**
   - Dùng hook `useSwitchChain()` để tự động kích hoạt ví chuyển sang Avalanche Fuji (Chain ID: `43113`).
