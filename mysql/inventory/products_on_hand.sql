CREATE TABLE `products_on_hand` (
  `product_id` int NOT NULL,
  `quantity` int NOT NULL,
  PRIMARY KEY (`product_id`),
  CONSTRAINT `products_on_hand_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;