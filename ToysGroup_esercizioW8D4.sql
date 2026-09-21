-- task1b /2: progettazione logica
-- Traduzione dello schema concettuale in tabelle relazionali 
-- (Product, Region, Sales) con chiavi primarie ed esterne

USE ToysGroup;

-- Elimino le tabelle esistenti nell'ordine corretto (prima Sales, che dipende dalle altre due) per completare la task 2
DROP TABLE IF EXISTS Sales;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Region;

CREATE TABLE Product (
ProductID VARCHAR(100)    PRIMARY KEY,
ProductName VARCHAR(100) NOT NULL,
Category VARCHAR(100) NOT NULL,
Brand VARCHAR(100),
UnitPrice DECIMAL(10,2) NOT NULL
);
CREATE TABLE Region (
RegionID VARCHAR(100)    PRIMARY KEY,
RegionName VARCHAR(100) NOT NULL,
State VARCHAR(100) NOT NULL,
Continent VARCHAR(100)
);
-- Ho lasciato Brand e Continent senza NOT NULL perchè sono informazioni descrittive non essenziali allo scenario.
CREATE TABLE Sales (
TransactionID INT         PRIMARY KEY,
ProductID VARCHAR(100) NOT NULL,
RegionID VARCHAR(100) NOT NULL,
Quantity INT NOT NULL,
Amount DECIMAL(10,2) NOT NULL,
SaleDate DATE NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
FOREIGN KEY (RegionID) REFERENCES Region(RegionID)
);
-- Task 3: popolamento dati
-- Product: almeno 4 prodotti, almeno 2 categorie diverse
INSERT INTO Product (ProductID, ProductName, Category, Brand, Unitprice) VALUES
("Toys-100","Robot Trasformabile", "ActionFigures", "Hasbro", 29.90),
("Toys-200", "Statuetta Supereroe", "ActionFigures","Marvel", 19.90),
("Blocks-100","Set Mattoncini Auto", "BuildingBlocks", "Lego", 59.90),
("Blocks-200", "Set Mattoncini Castello", "BuildingBlocks", "Lego", 74.90),
("Peluche-100", "Orsettone Peluche", "Peluche", "Trudi", 24.90),
("Peluche-200", "Coniglio Peluche", "Peluche", "Jellycat", 19.90);

-- Region: almeno 3 stati, almeno 2 regioni diverse
INSERT INTO Region (RegionID, RegionName, State, Continent) VALUES
("R-FR", "Westeurope", "France", "Europe"),
("R-IT", "Westeurope", "Italy", "Europe"),
("R-US", "NorthAmerica", "UnitedStates", "America");

-- Sales: almeno 10 transazioni, su più anni
INSERT INTO Sales (TransactionID, ProductID, RegionID, Quantity, Amount, SaleDate) VALUES
(1, "Toys-100", "R-FR", 2, 59.80, "2023-04-18"),
(2, "Toys-100", "R-IT", 3, 89.70, "2023-06-15"),
(3, "Peluche-200", "R-IT", 2, 39.80, "2023-06-08"),
(4, "Blocks-100", "R-US", 4, 239.60, "2023-12-18"),
(5, "Peluche-100", "R-FR", 2, 49.80, "2024-01-05"),
(6, "Blocks-200", "R-FR", 3, 224.70, "2024-03-03"),
(7, "Toys-200", "R-US", 3, 59.70, "2024-03-14"),
(8, "Peluche-200", "R-IT", 2, 39.80, "2024-08-22"),
(9, "Blocks-200", "R-IT", 3, 224.70, "2024-12-15"),
(10, "Toys-200", "R-US", 2, 39.80, "2025-01-05");

-- Task 4a: Integrità e JOIN
-- punto 1: verifica univocità PK
SELECT ProductID, COUNT(*) AS conteggio
FROM Product
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT RegionID, COUNT(*) AS conteggio
FROM Region
GROUP BY RegionID
HAVING COUNT(*) > 1;

SELECT TransactionID, COUNT(*) AS conteggio
FROM Sales
GROUP BY TransactionID
HAVING COUNT(*) > 1;

-- Punto 2 e 3: INNER JOIN con colonna booleana
SELECT
Sales.ProductID,
Product.Category,
Region.State,
Region.RegionName,
Sales.SaleDate,
(DATEDIFF(CURDATE(), Sales.SaleDate) > 180) AS OltreSeiMesi
FROM Sales
INNER JOIN Product ON Sales.ProductID = Product.ProductID
INNER JOIN Region ON Sales.RegionID = Region.RegionID;

-- Verifica: nessuna riga persa nel JOIN
SELECT COUNT(*) FROM Sales;

SELECT COUNT(*)
FROM Sales
INNER JOIN Product ON Sales.ProductID = Product.ProductID
INNER JOIN Region ON Sales.RegionID = Region.RegionID;

-- Ho verificato l'univocità delle chiavi primarie con tre query GROUP BY/HAVING (una per tabella), che confermano nessun duplicato. Ho poi costruito l'elenco delle transazioni con un INNER JOIN tra Sales, Product e Region, aggiungendo una colonna booleana calcolata con DATEDIFF per segnalare le vendite più vecchie di 180 giorni. Ho verificato che il JOIN non perdesse righe confrontando il COUNT di Sales con quello del risultato del JOIN.

-- Task 4b: Aggregazioni e raggruppamenti
-- Punto 1: fatturato totale per prodotto e per anno
SELECT
ProductID, YEAR(SaleDate) AS Anno,
SUM(Amount) AS FatturatoTotale
FROM Sales
GROUP BY ProductID, YEAR(SaleDate);

-- Punto 2: fatturato totale per stato e per anno,
-- ordinato per data e per fatturato decrescente
SELECT
Region.State, YEAR(Sales.SaleDate) AS Anno,
SUM(Sales.Amount) AS FatturatoTotale
FROM Sales
INNER JOIN Region ON Sales.RegionID = Region.RegionID
GROUP BY Region.State, YEAR(Sales.SaleDate)
ORDER BY Anno, FatturatoTotale DESC;

-- Punto 3: categoria di prodotto più richiesta (quantità totale venduta)
SELECT
Product.Category,
SUM(Sales.Quantity) AS QuantitaTotale
FROM Sales
INNER JOIN Product ON Sales.ProductID = Product.ProductID
GROUP BY Product.Category
ORDER BY QuantitaTotale DESC
LIMIT 1;
-- Ho calcolato il fatturato totale per prodotto e anno, e per stato e anno (ordinato per data e fatturato decrescente), usando SUM e la funzione built-in YEAR() per estrarre l'anno dalla data. Ho poi individuato la categoria di prodotto più richiesta in termini di quantità venduta totale.
-- Task 4c: Subquery e CTE

-- Versione 1: con subquery
SELECT ProductID, SUM(Quantity) AS QuantitaTotale
FROM Sales
WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
GROUP BY ProductID
HAVING SUM(Quantity) > (
SELECT AVG(TotaleProdotto)
FROM (
SELECT SUM(Quantity) AS TotaleProdotto
FROM Sales
WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
GROUP BY ProductID) AS venditeAnno);

-- Versione 2: stessa domanda, con CTE
WITH venditeAnno AS (
SELECT ProductID, SUM(Quantity) AS TotaleProdotto
FROM Sales
WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
GROUP BY ProductID),
mediaAnno AS (
SELECT AVG(TotaleProdotto) AS Media
FROM venditeAnno)
SELECT ProductID, TotaleProdotto AS QuantitaTotale
FROM venditeAnno, mediaAnno
WHERE TotaleProdotto > Media;
-- Ho trovato i prodotti venduti sopra la media dell'ultimo anno in due modi: prima con una subquery dentro un HAVING, poi con una CTE che isola lo stesso calcolo in un WITH. La media è sempre calcolata con una query, non scritta a mano, e i due metodi danno lo stesso risultato.

-- Task 4d: Window Functions
-- Punto 1: posizione in classifica per fatturato, dentro la propria categoria
SELECT
Product.ProductID, Product.Category,
SUM(Sales.Amount) AS FatturatoProdotto,
RANK() OVER (PARTITION BY Product.Category
ORDER BY SUM(Sales.Amount) DESC
) AS PosizioneInCategoria
FROM Sales
INNER JOIN Product ON Sales.ProductID = Product.ProductID
GROUP BY Product.ProductID, Product.Category;

-- Task 4e: Prodotti invenduti e VIEW
-- Punto 1: prodotti invenduti, con LEFT JOIN + IS NULL
SELECT Product.ProductID, Product.ProductName
FROM Product
LEFT JOIN Sales ON Product.ProductID = Sales.ProductID
WHERE Sales.TransactionID IS NULL;

-- Punto 2: stessa domanda, con NOT IN (confronto di insiemi)
SELECT ProductID, ProductName
FROM Product
WHERE ProductID NOT IN (SELECT ProductID FROM Sales);

-- Punto 3: vista denormalizzata sui prodotti
CREATE VIEW vw_prodotti_dettaglio AS
SELECT ProductID, ProductName, Category
FROM Product;

-- Punto 4: vista per le informazioni geografiche
CREATE VIEW vw_vendite_geografiche AS
SELECT
Sales.TransactionID, Sales.SaleDate, Sales.Amount, Region.RegionName, Region.State, Region.Continent
FROM Sales
INNER JOIN Region ON Sales.RegionID = Region.RegionID;

-- Punto 2: totale progressivo del fatturato della regione, fino a quella data
SELECT
Sales.TransactionID, Region.RegionID, Sales.SaleDate, Sales.Amount,
SUM(Sales.Amount) OVER (
PARTITION BY Region.RegionID
ORDER BY Sales.SaleDate
) AS TotaleProgressivoRegione
FROM Sales
INNER JOIN Region ON Sales.RegionID = Region.RegionID;

-- Punto 3: confronto col fatturato della transazione precedente, stessa regione
SELECT
Sales.TransactionID, Region.RegionID, Sales.SaleDate, Sales.Amount,
LAG(Sales.Amount) OVER (
PARTITION BY Region.RegionID
ORDER BY Sales.SaleDate
) AS ImportoTransazionePrecedente
FROM Sales
INNER JOIN Region ON Sales.RegionID = Region.RegionID;

-- GOVERNANCE E PRIVACY APPLICATA
-- Caso 1: causa
-- La vista mostra anche il costo d'acquisto, che è un dato sensibile e non doveva vedersi da fuori
-- Caso 1: versione corretta
CREATE VIEW vw_prodotti_rivenditori AS
SELECT ProductID, ProductName, Category FROM Product;


-- Caso 2: causa
-- I contatti dei fornitori sono condivisi col marketing, che non ne ha bisogno per lavorare
-- Caso 2: versione corretta
CREATE TABLE SupplierContact (
SupplierID INT,
Phone  VARCHAR(20)
);
-- accesso solo per il reparto Acquisti, non condiviso col marketing


-- Caso 3: causa
-- La vista per il commerciale mostra anche costo d'acquisto e margine, che dovrebbero vedere solo i manager
-- Caso 3: versione corretta
CREATE VIEW vw_sales_generale AS
SELECT SalesID, SalesAmount FROM Sales;
CREATE VIEW vw_sales_margine_management AS
SELECT SalesID, SalesAmount, PurchaseCost, Margin FROM Sales;
-- accesso solo per il management


-- Caso 4: causa
-- I log vengono salvati per sempre, senza nessuna scadenza
-- Caso 4: versione corretta
CREATE TABLE ReportAccessLog (
    UserID     INT,
    QueryText  VARCHAR(1000),
    AccessDate DATETIME
);
-- eliminare o archiviare i log più vecchi di 90 giorni