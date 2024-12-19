# import math
# from time import now
# from sys import simdwidthof
# from algorithm.functional import vectorize

# alias nelts = simdwidthof[DType.float32] () * 32
# alias N = 1024


# fn eval_A(i:Int, j:Int) ->Float32:
#     return (1.0/((i+j)*(i+j+1)/2+i+1)).cast[DType.float32]()

# fn eval_A_times_u(N:Int, u:SIMD[DType.float32, 1024], inout Au:SIMD[DType.float32, 1024]):
#     for i in range(N):
#         @parameter
#         fn dot[nelts: Int] (j: Int):
#             Au[i] += eval_A(i,j) * u[j]
#         vectorize[dot, nelts, size = 1024] ()

# fn eval_At_times_u(N:Int, u:SIMD[DType.float32, 1024], inout Au:SIMD[DType.float32, 1024]):
#     for i in range(N):
#         @parameter
#         fn dot[nelts: Int] (j: Int):
#             Au[i] += eval_A(i,j) * u[j]
#         vectorize[dot, nelts, size = 1024] ()

# fn eval_AtA_times_u(N:Int, u:SIMD[DType.float32, 1024], inout AtAu:SIMD[DType.float32, 1024]):
#     var v = SIMD[DType.float32, 1024] (0)
#     eval_A_times_u(N,u,v)
#     eval_At_times_u(N,v,AtAu)

# fn main():
#     print(nelts)
#     var v = SIMD[DType.float32, 1024] (0)
#     var u = SIMD[DType.float32, 1024] (1)

#     start = now()
#     for _ in range(10):
#         eval_AtA_times_u(N,u,v)
#         eval_AtA_times_u(N,v,u)
    
#     var vBv:Float32 = 0.0
#     var vv:Float32 = 0.0

#     @parameter
#     fn dot[nelts: Int] (i: Int):
#         vBv += u[i] * v[i]
#         vv += v[i] * v[i]
#     vectorize[dot, nelts, size = N] ()

#     print(math.sqrt(vBv/vv))

#     end = now()
#     total_time = (end - start)/1000000000
#     print("Total time taken: ",total_time)

################################################===================================#####################################
# import math
# from time import now
# from sys import simdwidthof
# from algorithm.functional import vectorize
# from memory import memset_zero

# alias simd_width = simdwidthof[DType.float32] () * 32
# alias size = 5000


# fn eval_A(i:Int, j:Int) ->Float32:
#     return (1.0/((i+j)*(i+j+1)/2+i+1)).cast[DType.float32]()

# fn eval_A_times_u(N:Int, u:UnsafePointer[Float32], Au:UnsafePointer[Float32]):
#     for i in range(N):
#         Au[i] = 0
#         for j in range(N):
#             Au[i] += eval_A(i,j)*u[j]
    
# fn eval_At_times_u(N:Int, u:UnsafePointer[Float32], Au:UnsafePointer[Float32]):
#     for i in range(N):
#         Au[i] = 0
#         for j in range(N):
#             Au[i] += eval_A(j,i)*u[j]

# fn eval_AtA_times_u(N:Int, u:UnsafePointer[Float32], AtAu:UnsafePointer[Float32]):
#     var v = UnsafePointer[Float32].alloc(size)
#     eval_A_times_u(N,u,v)
#     eval_At_times_u(N,v,AtAu)

# fn main():
#     var v = UnsafePointer[Float32].alloc(size)
#     var u = UnsafePointer[Float32].alloc(size)
#     @parameter
#     fn closure[simd_width: Int](i: Int):
#         u.store[width=simd_width](i, 1)

#     vectorize[closure, simd_width](size)

#     start = now()
#     for _ in range(10):
#         eval_AtA_times_u(size,u,v)
#         eval_AtA_times_u(size,v,u)
    
#     var vBv:Float32 = 0.0
#     var vv:Float32 = 0.0

#     @parameter
#     fn dot[simd_width: Int] (i: Int):
#         vBv += u[i] * v[i]
#         vv += v[i] * v[i]
#     vectorize[dot, simd_width, size = size] ()

#     print(math.sqrt(vBv/vv))

#     end = now()
#     total_time = (end - start)/1000000000
#     print("Total time taken: ",total_time)
    
################################################============================================############################

import math
from time import now
from sys import simdwidthof
from algorithm.functional import vectorize
from memory import memset_zero


alias size = 5000


alias simd_size = 4096
alias simd_width = simdwidthof[DType.float32] () * 32
alias total_iters = simd_size/simd_width


fn eval_A2(i: SIMD[DType.float32, simd_size], j: Int) -> SIMD[DType.float32, simd_size]:
    var x = (1.0 / ((i + j) * (i + j + 1) / 2 + i + 1))
    return x

fn eval_A(i: Int, j: Int) -> Float32:
    # Computes the matrix element A[i, j] as a Float32 value
    return (1.0 / ((i + j) * (i + j + 1) / 2 + i + 1)).cast[DType.float32]()

fn eval_A1(i: Int, j: SIMD[DType.float32, simd_size]) -> SIMD[DType.float32, simd_size]:
    # Computes multiple elements of A[i, j] in parallel using SIMD
    var x = (1.0 / ((i + j) * (i + j + 1) / 2 + i + 1))
    return x

fn eval_A_times_u(N:Int, u:UnsafePointer[Float32], Au:UnsafePointer[Float32], j_new:SIMD[DType.float32, size]):
    # Processes rows of the matrix and multiplies them with vector `u`
    j = j_new.slice[simd_size]()
    for i in range(N):  # Loop over all rows of the matrix
        if i < simd_size:
            # Use SIMD operations for rows within the SIMD width
            Au[i] = (eval_A1(i,j) * u.load[width=simd_size]()).reduce_add()
        else:
            # Fallback to scalar loop for rows outside the SIMD width
            for j in range(simd_size, size):
                Au[i] += eval_A(i,j)*u[j]


fn eval_At_times_u(N:Int, u:UnsafePointer[Float32], Au:UnsafePointer[Float32], j_new:SIMD[DType.float32, size]):
    j = j_new.slice[simd_size]()
    for i in range(N):
        if i < simd_size:
            Au[i] = (eval_A2(j,i) * u.load[width=simd_size]()).reduce_add()
        else:
            for j in range(simd_size, size):
                Au[i] += eval_A(j,i)*u[j]

fn eval_AtA_times_u(N:Int, u:UnsafePointer[Float32], AtAu:UnsafePointer[Float32], j_new:SIMD[DType.float32, size]):
    var v = UnsafePointer[Float32].alloc(size)
    eval_A_times_u(N,u,v,j_new)
    eval_At_times_u(N,v,AtAu,j_new)

fn main():
    var v = UnsafePointer[Float32].alloc(size)
    var u = UnsafePointer[Float32].alloc(size)
    @parameter
    fn closure[simd_width: Int](i: Int):
        u.store[width=simd_width](i, 1)

    vectorize[closure, simd_width](size)

    var j = UnsafePointer[Float32].alloc(size)
    for i in range(size):
        j.store(i,i)
    var j_new = j.load[width=size]()

    start = now()
    for _ in range(10):
        eval_AtA_times_u(size,u,v,j_new)
        eval_AtA_times_u(size,v,u, j_new)
    
    var vBv:Float32 = 0.0
    var vv:Float32 = 0.0

    @parameter
    fn dot[simd_width: Int] (i: Int):
        vBv += u[i] * v[i]
        vv += v[i] * v[i]
    vectorize[dot, simd_width, size = size] ()

    print(math.sqrt(vBv/vv))

    end = now()
    total_time = (end - start)/1000000000
    print("Total time taken: ",total_time)