# FILE READING


import csv
import numpy as np


from sklearn.cluster import KMeans


#practice of reading files
def read_me():
    sampleFile = open('smalldata.csv', 'rb')
    reader = csv.reader(sampleFile)


def usewith():
    clust1 = []
    clusterpoints = []
    with open('smalldata.csv') as smalldata:
        newReader = csv.reader(smalldata)
        for row in newReader:
            if row[0] !=  "\ufeffCLOSEST_DEF":
                clust1.append(row)
    points = np.array(clust1)
    kmeans = KMeans(n_clusters=3, random_state=np.random).fit(points)
    for i in range(len(points)):
        point = points[i]
        label = kmeans.labels_[i]
        clusterpoints.append([[float(point[0]), float(point[1]), label]])
    # print(kmeans.labels_)
    # print(kmeans.cluster_centers_)
    print(clusterpoints)


# Run your crap below
usewith()
