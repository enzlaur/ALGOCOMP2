# FILE READING


import csv
import numpy as np
from numpy.random import rand
import matplotlib.pyplot as plt


# from sklearn2.cluster import KMeans

from sklearn.cluster import KMeans


# from sklearn.cluster.k_means_ import3 freq as freqme
from sklearn.cluster.k_means_ import printfrequency as kmeanfreq
from sklearn.cluster.k_means_ import getfreq as kmeangetfreq
from sklearn.utils.validation import printfreq as validfreq
from sklearn.utils.validation import getfreq as validgetfreq
from sklearn.cluster.spectral import printfreq as spectralfreq
from sklearn.cluster.k_means_ import getlloyditer as lloyditer
from sklearn.base import printfrequency as basefreq
from sklearn.base import getfreq as basegetfreq
from sklearn.metrics.pairwise import getfreq as pairgetfreq
from sklearn.metrics.pairwise import printfrequency as pairfreq
from sklearn.utils.__init__ import printfrequency as initfreq
from sklearn.utils.__init__ import getfreq as initgetfreq
from sklearn.utils.extmath import printfrequency as extmathfreq
from sklearn.utils.extmath import getfreq as extmathgetfreq
from sklearn.externals.joblib.parallel import printfrequency as parallelfreq
from sklearn.externals.joblib.parallel import getfreq as parallelgetfreq
from numpy.core.numeric import printfreq as numericfreq
from numpy.core.numeric import getfreq as numericgetfreq
from numpy.core.fromnumeric import printfreq as fromnumericfreq
from numpy.core.fromnumeric import getfreq as fromnumericgetfreq


# from sklearn.cluster._k_means_elkan import k_means_elkan
# from sklearn.cluster._k_means_elka import printfrequency as elkanfreq
# from sklearn.cluster._k_means_elkan import getfreq as elkangetfreq

# kme = k_means_elkan
# kme
#practice of reading files
def read_me():
    sampleFile = open('smalldata.csv', 'rb')
    reader = csv.reader(sampleFile)


def usewith(nclusters, algotype, dataname):
    data100 = "smalldata.csv"
    data2k = "shot-def-dist-2k.csv"
    data5k = "shot-def-dist-5k.csv"
    data10k = "shot-def-dist-10k.csv"
    missed10k = "missed-shot-def-dist-10k.csv"
    currymissed = "curry-missed-shot.csv"
    currymade = "curry-shot-made.csv"

    # if algotype == "full":
    #     print("HAHAHA no. Reverting to elkan")
    #     algotype = "elkan"

    if dataname == "data100":
        dataname = data100
    elif dataname == "data2k":
        dataname = data2k
    elif dataname == "data5k":
        dataname = data5k
    elif dataname == "data10k":
        dataname = data10k
    elif dataname == "missed":
        dataname = missed10k
    elif dataname == "currymissed":
        dataname = currymissed
    elif dataname == "currymade":
        dataname = currymade
    else:
        dataname = data100

    clust1 = []
    clusterpoints = []
    # acquire data from csv
    with open(dataname) as smalldata:
        newReader = csv.reader(smalldata)
        for row in newReader:
            if row[0] !=  "\ufeffCLOSEST_DEF":
                clust1.append(row)
    # set the points
    points = np.array(clust1)
    # start kmeans processing
    kmeans = KMeans(n_clusters=nclusters, random_state=np.random, algorithm=algotype)
    kmeans.fit(points)
    # print the freq count per class (kmeans, validations, etc)
    initfreq()
    kmeanfreq()
    validfreq()
    spectralfreq()
    basefreq()
    pairfreq()
    extmathfreq()
    parallelfreq()
    numericfreq()
    fromnumericfreq()
    # elkanfreq()
    # total
    totalfreq = kmeangetfreq() + validgetfreq() + basegetfreq() + pairgetfreq() + initgetfreq() + extmathgetfreq() + parallelgetfreq() + numericgetfreq() + fromnumericgetfreq()
    # print total freq
    print("Total freq count: " + str(totalfreq))
    # print expected range of freq count
    if algotype == "full":
        print("Expected BigO/FreqCount for Lloyd/full")
        print("O(knt) = " + str(nclusters) + "*" + str(len(points)) +
              "*" + str(lloyditer()) + " = " + str(nclusters*len(points)*lloyditer()))
    else:
        print("Expected BigO for Elkan")
        print("From O() = ")
    for i in range(len(points)):
        point = points[i]
        label = kmeans.labels_[i]
        clusterpoints.append([float(point[0]), float(point[1]), label])
    for centers in kmeans.cluster_centers_:
        clusterpoints.append([float(centers[0]), float(centers[1]), 99])

    # print(kmeans.labels_)
    # print(kmeans.cluster_centers_)
    return clusterpoints


def colorchoices(x):
    return {
        0: 'red',
        1: 'blue',
        2: 'orange',
        3: 'pink',
        4: 'cyan',
        5: 'teal',
        99: 'green'
    }[x]


def startclustering():
    print("Enter the number of clusters (1-5)")
    num = input()
    print("Enter full/elkan")
    algotype = input()
    print("Choose betweek: data100, data5k, data10k, missed, currymade, currymissed")
    dataname = input()
    clusterpoints = usewith(int(num), str(algotype), str(dataname))
    fig, ax = plt.subplots()
    print("Number of cluster points (including center): ", len(clusterpoints))
    for i in range(len(clusterpoints)):
        point = clusterpoints[i]
        x = point[0]
        y = point[1]
        z = point[2]
        color = colorchoices(z)
        ax.scatter(x, y, c=color)
    ax.grid(True)
    plt.show()


def testmatplot():
    fig, ax = plt.subplots()
    for color in ['red', 'green', 'blue']:
        n = 100
        x, y = rand(2, n)
        scale = 200.0 * rand(n)
        ax.scatter(x, y, c=color, s=scale, label=color,alpha=0.3, edgecolors='none')
    ax.legend()
    ax.grid(True)
    plt.show()




# createscatter()
startclustering()
