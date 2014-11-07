
#!/usr/bin/env python2.7
'''
Assignment 1: Binary Multiplication

Team Number: 2
Student Names: Christian Tornqvist, Milad Taba 
'''
import unittest

def binary_mult(A,B):
    """
    Sig:    int[0..n-1], int[0..n-1] ==> int[0..2*n-1]
    Pre:    len(A) == len(B), A and B are represented as binary numbers with their MSB as leftmost element and LSB as the rightmost element. Len(A) > 0
    Post:   The result of multiplying A*B binary
    Example:    binary_mult([0,1,1],[1,0,0]) = [0,0,1,1,0,0]
    """
    length = len(A)

    if length > 1:
        A1, A2 = (A[:len(A)/2], A[len(A)/2:])
        B1, B2 = (B[:len(B)/2], B[len(B)/2:])

        pad_same_length(A1, B1)
        pad_same_length(A1, B2)
        pad_same_length(A2, B1)
        pad_same_length(A2, B2)

        A1B1 = binary_mult(A1, B1)
        A1B2 = binary_mult(A1, B2)
        A2B1 = binary_mult(A2, B1)
        A2B2 = binary_mult(A2, B2)

        cross_sum = binary_add(A1B2, A2B1)
        
        Left = append_n_times(A1B1, length)
        Middle = append_n_times(cross_sum, length/2)
        Right = A2B2

        mid_sum = binary_add(Left,Middle)
        final_sum = binary_add(mid_sum, Right)

        length_modifier(final_sum, length)
        return final_sum
    else:
        return [A[0]*B[0]]

    
def length_modifier(X, length):
    """
    Sig:    int[0..n-1], int ==> int[0..2*length-1]
    Pre:    x = len(X)
    Post:   len(X) = 2*x
    """
    X_length = len(X)
    if (X_length < length*2):
        prepend_n_times(X, length*2 - X_length)
    else:
        pop_n_times(X, X_length - length*2)

def pad_same_length(X, Y):
    """
    Sig:    int[0..n-1], int[0..m-1]int ==> int[0..max(n,m)-1]
    Pre:    y = len(Y), x = len(X), p = X, q = Y
    Post:   len(Y) == max(x,y), len(X) == max(x,y) The list of p and q that has least elements will be padded with max(y,x) - min(y,x) 0's. len(Y) % 2 == 0 and len(X) % 2 == 0
    """
    Length_X = len(X)
    Length_Y = len(Y)
    if (Length_X > Length_Y):
        pad_length = Length_X - Length_Y
        prepend_n_times(Y, pad_length)
    else:
        pad_length = Length_Y - Length_X
        prepend_n_times(X, pad_length)
    if (len(X) % 2 != 0 and len(X) != 1):
        X.insert(0,0)
        Y.insert(0,0)

def binary_add(X, Y):
    """
    Sig:    int[0..n-1], int[0..n-1] ==> int[0..m-1]
    Pre:    X and Y are represented as binary numbers with MSB as leftmost element and LSB as the rightmost element
    Post:   The result of adding X and Y in binary as a binary addidtion.
    """
    pad_same_length(X,Y)
    X.reverse()
    Y.reverse()
    index = 0
    temp = 0
    carry = 0
    result = [0]*(len(X))
    for X_element in X:
        # Variant: X_element takes all values in X
        result[index] = (Y[index] + X_element + carry) % 2
        if (Y[index] + X_element + carry) > 1:
            carry = 1
        else:
            carry = 0
        index +=1
    if carry == 1:
        result.extend([carry])
    result.reverse()
    return result

def pop_n_times(X,n):
    """
    Sig:    int[0..n-1], int ==> int[0..m-1]
    Pre:    len(X) >= n, x = X
    Post:   x without its n first elements
    """
    for i in xrange(0,n):
        X.pop(0)
    return X

def append_n_times(X, n):
    """
    Sig:    int[0..n-1], int ==> int[0..m-1]
    Pre:    x = X
    Post:   x with the list [0]*n appended to it
    """
    Y = []
    for i in xrange(0,n):
        Y.insert(0,0)
    X += Y
    return X


def prepend_n_times(X, n):
    """
    Sig:    int[0..n-1], int ==> int[0..m-1]
    Pre:    x = X
    Post:   The list [0]*n with x appended to it
    """
    for i in xrange(0,n):
        X.insert(0,0)
    return X
