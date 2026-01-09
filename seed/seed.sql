##create database targets;
##use targets;

CREATE TABLE `targets` (
  `id` int NOT NULL AUTO_INCREMENT ,
  `target` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO `targets` (`target`, `tag`) VALUES
("https://www.target.se", 'prod,https'),
("https://api.target.se", 'prod,api,https');