message = "polar codes are employed in 5g due better performance and simplicity   ".lower()
st = list(message)
print(message)
i  = 0
p  = []
ci = []
nl = len(st)

while(len(st) > 0):
    c = st[i]
    ci.append(c) 
    j = 0
    p.append(0)
    while(j < len(st)):
        
        if st[j] == c:
            p[len(p)-1] += 1
            st.pop(j)
        else:
            j += 1
    p[len(p)-1] /= nl
    
print("Numero de Letras = "+str(nl))

for i in range(len(ci)):
    print("p('"+ci[i]+"') = "+str(p[i]))
