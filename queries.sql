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
ORDER BY Perecentage_of_Total DESC
LIMIT 10;
-- Output 1
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
+----------------+-------------------+----------------------+

-- 2. Number of providers per member, grouped by state

SELECT 
    A.State,
    A.Members,
    B.Providers,
    ROUND(B.Providers/A.Members,2) AS Providers_per_Member
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
ON A.State = B.State
ORDER BY Providers_per_Member DESC
LIMIT 10;
-- Output 2
+--------------+---------+-----------+----------------------+
| State        | Members | Providers | Providers_per_Member |
+--------------+---------+-----------+----------------------+
| Oregon       |      18 |        25 |                 1.39 |
| Idaho        |      13 |        18 |                 1.38 |
| Wyoming      |      17 |        22 |                 1.29 |
| South Dakota |      17 |        19 |                 1.12 |
| North Dakota |      18 |        17 |                 0.94 |
| New Mexico   |      35 |        31 |                 0.89 |
| Oklahoma     |      25 |        22 |                 0.88 |
| Hawaii       |      24 |        19 |                 0.79 |
| Utah         |      32 |        23 |                 0.72 |
| Kansas       |      44 |        25 |                 0.57 |
+--------------+---------+-----------+----------------------+

-- 3. Claim accuracy

-- Are in-network claims paid in compliance with state-required minimum payouts?
      
    -- 3a. Show all underpaid medical claims
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
    -- Output 3a
    +----------+----------------+------+--------+-----------+---------------+------------------+
    | Claim_ID | State          | Cost | Payout | Paid_Rate | Required_Rate | Amount_Underpaid |
    +----------+----------------+------+--------+-----------+---------------+------------------+
    |   400000 | Massachusetts  |   56 |  44.80 |      0.80 |          0.90 |             5.60 |
    |   400003 | New York       |  625 | 243.75 |      0.39 |          0.81 |           262.50 |
    |   400004 | New York       |  800 | 640.00 |      0.80 |          0.81 |             8.00 |
    |   400005 | New York       |   20 |  12.00 |      0.60 |          0.81 |             4.20 |
    |   400006 | North Carolina |   44 |  35.20 |      0.80 |          0.82 |             0.88 |
    |   400009 | New Hampshire  |   48 |  38.40 |      0.80 |          0.88 |             3.84 |
    |   400010 | New Jersey     |   25 |  20.00 |      0.80 |          0.89 |             2.25 |
    |   400011 | Pennsylvania   |  875 | 700.00 |      0.80 |          0.81 |             8.75 |
    |   400012 | Maine          |  800 | 640.00 |      0.80 |          0.87 |            56.00 |
    |   400014 | New Jersey     |  825 | 660.00 |      0.80 |          0.89 |            74.25 |
    +----------+----------------+------+--------+-----------+---------------+------------------+


    -- 3b. Show amount needed to pay to get to required minimum payout by state
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
    ORDER BY Amount_Underpaid DESC
    LIMIT 10;
    -- -- Output 3b
    +----------------+--------------+------------+--------------+------------------+
    | State          | Total_Claims | Total_Cost | Total_Payout | Amount_Underpaid |
    +----------------+--------------+------------+--------------+------------------+
    | New York       |         4584 |     818516 |    511555.63 |        151442.33 |
    | New Jersey     |         1808 |     334208 |    210127.20 |         87317.92 |
    | Massachusetts  |         1747 |     297677 |    194456.09 |         73453.21 |
    | Pennsylvania   |         2221 |     375943 |    238837.10 |         65676.73 |
    | Virginia       |         1031 |     200437 |    126943.02 |         53450.28 |
    | Ohio           |          628 |     111111 |     69851.29 |         25704.17 |
    | North Carolina |          671 |     119498 |     74583.09 |         23405.27 |
    | Maryland       |          490 |      79168 |     49245.90 |         22005.30 |
    | California     |          641 |     111013 |     70552.12 |         19368.41 |
    | Texas          |          252 |      40831 |     25742.25 |         10597.34 |
    +----------------+--------------+------------+--------------+------------------+


    -- 3c. Show total amount needed to pay to get to required minimum payout
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
    -- Output 3c
    +------------------+------------------+
    | Underpaid_Claims | Amount_Underpaid |
    +------------------+------------------+
    |            16336 |        617825.81 |
    +------------------+------------------+

