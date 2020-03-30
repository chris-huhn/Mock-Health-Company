-- Queries list: 

-- 1. How many members per state, and what percentage does each state have of total membership?
SELECT 
    State, 
    COUNT(Member_Name) AS 'Members per State',
    CONCAT (
        ROUND(
            COUNT(Member_Name) / (SELECT COUNT(Member_Name) FROM members) * 100, 2
        )
    , '%') AS Perecentage_of_Total
FROM members
GROUP BY State
ORDER BY Perecentage_of_Total DESC;

+----------------+-------------------+----------------------+
| State          | Members per State | Perecentage_of_Total |
+----------------+-------------------+----------------------+
| Pennsylvania   |               914 | 9.14%                |
| New Jersey     |               686 | 6.86%                |
| Massachusetts  |               677 | 6.77%                |
| Virginia       |               591 | 5.91%                |
| North Carolina |               460 | 4.60%                |
| California     |               430 | 4.30%                |
| Ohio           |               429 | 4.29%                |
| Maryland       |               333 | 3.33%                |
| Florida        |               253 | 2.53%                |
| Colorado       |               252 | 2.52%                |
| Illinois       |               249 | 2.49%                |

-- 2. Number of providers per member, grouped by state

SELECT 
    A.State,
    A.Members,
    B.Providers,
    ROUND(B.Providers/A.Members,2) AS 'Providers per Member'
FROM
    (SELECT
        State,
        COUNT(Member_ID) AS Members
    FROM members 
    GROUP BY State) AS A
INNER JOIN 
    (SELECT
        State,
        COUNT(Provider_ID) AS Providers
    FROM providers 
    GROUP BY State) AS B
ON A.State = B.State;

-- 3. Claim accuracy

-- 3a. Are in-network claims paid in compliance with state-required minimum payouts?
      
-- 3a(i). 
    -- Show all underpaid medical claims
    SELECT 
       procedure_claims.Claim_ID,
       procedure_claims.State, 
       procedure_claims.Cost,
       procedure_claims.Payout,
       ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) AS Paid_Rate,
       states.Medical_Cost_Share AS Required_Rate,
       (states.Medical_Cost_Share * procedure_claims.Cost) - procedure_claims.Payout AS Amount_Underpaid
    FROM procedure_claims
    INNER JOIN states
    ON procedure_claims.State = states.State
    WHERE 
        procedure_claims.Network_Status = "In-Network"
        AND ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) < states.Medical_Cost_Share
    LIMIT 10;

    -- Show amount needed to pay to get to required minimum payout by state
    SELECT
       procedure_claims.State,     
       COUNT(procedure_claims.Claim_ID) AS Total_Claims,
       SUM(procedure_claims.Cost) AS Total_Cost,
       SUM(procedure_claims.Payout) AS Total_Payout,
       SUM((states.Medical_Cost_Share * procedure_claims.Cost) - procedure_claims.Payout) AS Amount_Underpaid
    FROM procedure_claims
    INNER JOIN states
    ON procedure_claims.State = states.State
    WHERE 
        procedure_claims.Network_Status = "In-Network"
        AND ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) < states.Medical_Cost_Share
    GROUP BY procedure_claims.State
    ORDER BY Amount_Underpaid DESC;    

    -- Show total amount needed to pay to get to required minimum payout
    SELECT 
        COUNT(procedure_claims.Claim_ID) Underpaid_Claims,
        SUM((states.Medical_Cost_Share * procedure_claims.Cost) - procedure_claims.Payout) AS Amount_Underpaid
    FROM procedure_claims
    INNER JOIN states
    ON procedure_claims.State = states.State
    WHERE 
        procedure_claims.Network_Status = "In-Network"
        AND ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) < states.Medical_Cost_Share
    ;

-- 3a(ii). Show all overpaid/accurately medical claims
SELECT 
   procedure_claims.Claim_ID,
   procedure_claims.State, 
   procedure_claims.Cost,
   procedure_claims.Payout,
   ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) AS "Paid Rate",
   states.Medical_Cost_Share
FROM procedure_claims
INNER JOIN states
ON procedure_claims.State = states.State
WHERE 
    procedure_claims.Network_Status = "In-Network"
    AND ROUND(procedure_claims.Payout/procedure_claims.Cost, 2) > states.Medical_Cost_Share
;

-- 3a(iii) Show perectage of in-network claims underpaid, exactly paid, overpaid
-- In Tableau

