high_demand = [40 35 38 29;
36 35 39 42;
37 39 26 46;
29 40 48 30]
medium_demand = [26 21 24 13;
20 19 27 21;
14 22 19 21;
17 26 27 20]
low_demand = [17 12 15 12;
9 13 10 10;
6 15 17 11;
10 17 21 15] 
for i in 1:4
    println("")
    for j in 1:4
        print(high_demand[i,j]*0.4+medium_demand[i,j]*0.2+low_demand[i,j]*0.4)
        print(";")
    end
end