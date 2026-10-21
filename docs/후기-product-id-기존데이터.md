# 기존 후기 2건 바로잡기 (bohol-hideout)

코드 배포와 별개로, **Firebase Console에서 한 번** 손보면 카드에 ★가 바로 보입니다.
(실행은 상품 id를 확인한 뒤.)

## 카드가 읽는 값

- 홈/상품 카드: `shops/bohol-hideout` → `products[]` 중 **그 카드 SKU**의  
  `guest_rating`, `guest_review_count`
- `options[].base`만 고쳐서는 카드가 안 바뀝니다.

## Console 순서 (방법 A)

1. `products`에서 카드와 같은 **제주(0원·curated)** 줄의 `id`를 확인합니다.  
   (예: 부모 product id. `options[0].id`가 `base`인 그 부모.)
2. `reviews` 후기 2건에 각각 `product_id` = 그 상품 id 를 넣습니다.
3. 같은 상품 객체에  
   - `guest_review_count`: `2`  
   - `guest_rating`: `5`  
4. (선택) 그 상품의 `options` 중 `id == base`에도 같은 `guest_*`를 넣습니다.
5. 앱을 새로고침해 카드에 ★ 5.0 · 후기 2 가 보이는지 확인합니다.

## 주의

- `dive_star_grade` 등 다이브스타 필드는 건드리지 마세요.
- 잘못된 product id에 guest_*를 넣으면 다른 상품 카드에 별이 붙습니다.
