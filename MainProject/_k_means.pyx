# cython: profile=True
# Profiling is enabled by default as the overhead does not seem to be measurable
# on this specific use case.

# Author: Peter Prettenhofer <peter.prettenhofer@gmail.com>
#         Olivier Grisel <olivier.grisel@ensta.org>
#         Lars Buitinck
#
# License: BSD 3 clause

from libc.math cimport sqrt
import numpy as np
import scipy.sparse as sp
cimport numpy as np
cimport cython
from cython cimport floating

from ..utils.extmath import norm
from sklearn.utils.sparsefuncs_fast import assign_rows_csr
from sklearn.utils.fixes import bincount

ctypedef np.float64_t DOUBLE
ctypedef np.int32_t INT

global freq
freq = 0

def printfrequency():
    print("Freq from kmeans_elkan: " + str(freq))


def addfreq():
    global freq
    freq+=1
    print("lloydfreq: " + str(freq))


def addfreqby(b):
    global freq
    freq += b


def getfreq():
    global freq
    return freq


ctypedef floating (*DOT)(int N, floating *X, int incX, floating *Y,
                         int incY)

cdef extern from "cblas.h":
    double ddot "cblas_ddot"(int N, double *X, int incX, double *Y, int incY)
    float sdot "cblas_sdot"(int N, float *X, int incX, float *Y, int incY)

np.import_array()


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cpdef DOUBLE _assign_labels_array(np.ndarray[floating, ndim=2] X,
                                  np.ndarray[floating, ndim=1] x_squared_norms,
                                  np.ndarray[floating, ndim=2] centers,
                                  np.ndarray[INT, ndim=1] labels,
                                  np.ndarray[floating, ndim=1] distances):
    """Compute label assignment and inertia for a dense array

    Return the inertia (sum of squared distances to the centers).
    """
    cdef:
        unsigned int n_clusters = centers.shape[0]
        unsigned int n_features = centers.shape[1]
        unsigned int n_samples = X.shape[0]
        unsigned int x_stride
        unsigned int center_stride
        unsigned int sample_idx, center_idx, feature_idx
        unsigned int store_distances = 0
        unsigned int k
        np.ndarray[floating, ndim=1] center_squared_norms
        # the following variables are always double cause make them floating
        # does not save any memory, but makes the code much bigger
        DOUBLE inertia = 0.0
        DOUBLE min_dist
        DOUBLE dist
        DOT dot
    addfreq()
    if floating is float:
        center_squared_norms = np.zeros(n_clusters, dtype=np.float32)
        x_stride = X.strides[1] / sizeof(float)
        center_stride = centers.strides[1] / sizeof(float)
        dot = sdot
    else:
        center_squared_norms = np.zeros(n_clusters, dtype=np.float64)
        x_stride = X.strides[1] / sizeof(DOUBLE)
        center_stride = centers.strides[1] / sizeof(DOUBLE)
        dot = ddot

    if n_samples == distances.shape[0]:
        store_distances = 1

    for center_idx in range(n_clusters):
        addfreq()
        center_squared_norms[center_idx] = dot(
            n_features, &centers[center_idx, 0], center_stride,
            &centers[center_idx, 0], center_stride)

    for sample_idx in range(n_samples):
        addfreq()
        min_dist = -1
        for center_idx in range(n_clusters):
            addfreq()
            dist = 0.0
            # hardcoded: minimize euclidean distance to cluster center:
            # ||a - b||^2 = ||a||^2 + ||b||^2 -2 <a, b>
            dist += dot(n_features, &X[sample_idx, 0], x_stride,
                        &centers[center_idx, 0], center_stride)
            dist *= -2
            dist += center_squared_norms[center_idx]
            dist += x_squared_norms[sample_idx]
            if min_dist == -1 or dist < min_dist:
                min_dist = dist
                labels[sample_idx] = center_idx

        if store_distances:
            distances[sample_idx] = min_dist
        inertia += min_dist

    return inertia


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cpdef DOUBLE _assign_labels_csr(X, np.ndarray[DOUBLE, ndim=1] x_squared_norms,
                                np.ndarray[floating, ndim=2] centers,
                                np.ndarray[INT, ndim=1] labels,
                                np.ndarray[floating, ndim=1] distances):
    """Compute label assignment and inertia for a CSR input

    Return the inertia (sum of squared distances to the centers).
    """
    cdef:
        np.ndarray[floating, ndim=1] X_data = X.data
        np.ndarray[INT, ndim=1] X_indices = X.indices
        np.ndarray[INT, ndim=1] X_indptr = X.indptr
        unsigned int n_clusters = centers.shape[0]
        unsigned int n_features = centers.shape[1]
        unsigned int n_samples = X.shape[0]
        unsigned int store_distances = 0
        unsigned int sample_idx, center_idx, feature_idx
        unsigned int k
        np.ndarray[floating, ndim=1] center_squared_norms
        # the following variables are always double cause make them floating
        # does not save any memory, but makes the code much bigger
        DOUBLE inertia = 0.0
        DOUBLE min_dist
        DOUBLE dist
        DOT dot

    if floating is float:
        center_squared_norms = np.zeros(n_clusters, dtype=np.float32)
        dot = sdot
    else:
        center_squared_norms = np.zeros(n_clusters, dtype=np.float64)
        dot = ddot

    if n_samples == distances.shape[0]:
        store_distances = 1

    for center_idx in range(n_clusters):
            addfreq()
            center_squared_norms[center_idx] = dot(
                n_features, &centers[center_idx, 0], 1, &centers[center_idx, 0], 1)

    for sample_idx in range(n_samples):
        addfreq()
        min_dist = -1
        for center_idx in range(n_clusters):
            addfreq()
            dist = 0.0
            # hardcoded: minimize euclidean distance to cluster center:
            # ||a - b||^2 = ||a||^2 + ||b||^2 -2 <a, b>
            for k in range(X_indptr[sample_idx], X_indptr[sample_idx + 1]):
                dist += centers[center_idx, X_indices[k]] * X_data[k]
            dist *= -2
            dist += center_squared_norms[center_idx]
            dist += x_squared_norms[sample_idx]
            if min_dist == -1 or dist < min_dist:
                min_dist = dist
                labels[sample_idx] = center_idx
                if store_distances:
                    distances[sample_idx] = dist
        inertia += min_dist

    return inertia


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def _mini_batch_update_csr(X, np.ndarray[DOUBLE, ndim=1] x_squared_norms,
                           np.ndarray[floating, ndim=2] centers,
                           np.ndarray[INT, ndim=1] counts,
                           np.ndarray[INT, ndim=1] nearest_center,
                           np.ndarray[floating, ndim=1] old_center,
                           int compute_squared_diff):
    """Incremental update of the centers for sparse MiniBatchKMeans.

    Parameters
    ----------

    X : CSR matrix, dtype float
        The complete (pre allocated) training set as a CSR matrix.

    centers : array, shape (n_clusters, n_features)
        The cluster centers

    counts : array, shape (n_clusters,)
         The vector in which we keep track of the numbers of elements in a
         cluster

    Returns
    -------
    inertia : float
        The inertia of the batch prior to centers update, i.e. the sum
        distances to the closest center for each sample. This is the objective
        function being minimized by the k-means algorithm.

    squared_diff : float
        The sum of squared update (squared norm of the centers position
        change). If compute_squared_diff is 0, this computation is skipped and
        0.0 is returned instead.

    Both squared diff and inertia are commonly used to monitor the convergence
    of the algorithm.
    """
    cdef:
        np.ndarray[floating, ndim=1] X_data = X.data
        np.ndarray[int, ndim=1] X_indices = X.indices
        np.ndarray[int, ndim=1] X_indptr = X.indptr
        unsigned int n_samples = X.shape[0]
        unsigned int n_clusters = centers.shape[0]
        unsigned int n_features = centers.shape[1]

        unsigned int sample_idx, center_idx, feature_idx
        unsigned int k
        int old_count, new_count
        DOUBLE center_diff
        DOUBLE squared_diff = 0.0

    # move centers to the mean of both old and newly assigned samples
    for center_idx in range(n_clusters):
        addfreq()
        old_count = counts[center_idx]
        new_count = old_count

        # count the number of samples assigned to this center
        for sample_idx in range(n_samples):
            addfreq()
            if nearest_center[sample_idx] == center_idx:
                new_count += 1

        if new_count == old_count:
            # no new sample: leave this center as it stands
            continue

        # rescale the old center to reflect it previous accumulated weight
        # with regards to the new data that will be incrementally contributed
        if compute_squared_diff:
            old_center[:] = centers[center_idx]
        centers[center_idx] *= old_count

        # iterate of over samples assigned to this cluster to move the center
        # location by inplace summation
        for sample_idx in range(n_samples):
            addfreq()
            if nearest_center[sample_idx] != center_idx:
                continue

            # inplace sum with new samples that are members of this cluster
            # and update of the incremental squared difference update of the
            # center position
            for k in range(X_indptr[sample_idx], X_indptr[sample_idx + 1]):
                centers[center_idx, X_indices[k]] += X_data[k]

        # inplace rescale center with updated count
        if new_count > old_count:
            # update the count statistics for this center
            counts[center_idx] = new_count

            # re-scale the updated center with the total new counts
            centers[center_idx] /= new_count

            # update the incremental computation of the squared total
            # centers position change
            if compute_squared_diff:
                for feature_idx in range(n_features):
                    squared_diff += (old_center[feature_idx]
                                     - centers[center_idx, feature_idx]) ** 2

    return squared_diff


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def _centers_dense(np.ndarray[floating, ndim=2] X,
        np.ndarray[INT, ndim=1] labels, int n_clusters,
        np.ndarray[floating, ndim=1] distances):
    """M step of the K-means EM algorithm

    Computation of cluster centers / means.

    Parameters
    ----------
    X : array-like, shape (n_samples, n_features)

    labels : array of integers, shape (n_samples)
        Current label assignment

    n_clusters : int
        Number of desired clusters

    distances : array-like, shape (n_samples)
        Distance to closest cluster for each sample.

    Returns
    -------
    centers : array, shape (n_clusters, n_features)
        The resulting centers
    """
    ## TODO: add support for CSR input
    cdef int n_samples, n_features
    n_samples = X.shape[0]
    n_features = X.shape[1]
    cdef int i, j, c
    cdef np.ndarray[floating, ndim=2] centers
    if floating is float:
        centers = np.zeros((n_clusters, n_features), dtype=np.float32)
    else:
        centers = np.zeros((n_clusters, n_features), dtype=np.float64)

    n_samples_in_cluster = bincount(labels, minlength=n_clusters)
    empty_clusters = np.where(n_samples_in_cluster == 0)[0]
    # maybe also relocate small clusters?

    if len(empty_clusters):
        # find points to reassign empty clusters to
        far_from_centers = distances.argsort()[::-1]

        for i, cluster_id in enumerate(empty_clusters):
            addfreq()
            # XXX two relocated clusters could be close to each other
            new_center = X[far_from_centers[i]]
            centers[cluster_id] = new_center
            n_samples_in_cluster[cluster_id] = 1

    for i in range(n_samples):
        addfreq()
        for j in range(n_features):
            addfreq()
            centers[labels[i], j] += X[i, j]

    centers /= n_samples_in_cluster[:, np.newaxis]

    return centers


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def _centers_sparse(X, np.ndarray[INT, ndim=1] labels, n_clusters,
        np.ndarray[floating, ndim=1] distances):
    """M step of the K-means EM algorithm

    Computation of cluster centers / means.

    Parameters
    ----------
    X : scipy.sparse.csr_matrix, shape (n_samples, n_features)

    labels : array of integers, shape (n_samples)
        Current label assignment

    n_clusters : int
        Number of desired clusters

    distances : array-like, shape (n_samples)
        Distance to closest cluster for each sample.

    Returns
    -------
    centers : array, shape (n_clusters, n_features)
        The resulting centers
    """
    cdef int n_features = X.shape[1]
    cdef int curr_label

    cdef np.ndarray[floating, ndim=1] data = X.data
    cdef np.ndarray[int, ndim=1] indices = X.indices
    cdef np.ndarray[int, ndim=1] indptr = X.indptr

    cdef np.ndarray[floating, ndim=2, mode="c"] centers
    cdef np.ndarray[np.npy_intp, ndim=1] far_from_centers
    cdef np.ndarray[np.npy_intp, ndim=1, mode="c"] n_samples_in_cluster = \
        bincount(labels, minlength=n_clusters)
    cdef np.ndarray[np.npy_intp, ndim=1, mode="c"] empty_clusters = \
        np.where(n_samples_in_cluster == 0)[0]
    cdef int n_empty_clusters = empty_clusters.shape[0]

    if floating is float:
        centers = np.zeros((n_clusters, n_features), dtype=np.float32)
    else:
        centers = np.zeros((n_clusters, n_features), dtype=np.float64)

    # maybe also relocate small clusters?

    if n_empty_clusters > 0:
        # find points to reassign empty clusters to
        far_from_centers = distances.argsort()[::-1][:n_empty_clusters]

        # XXX two relocated clusters could be close to each other
        assign_rows_csr(X, far_from_centers, empty_clusters, centers)

        for i in range(n_empty_clusters):
            n_samples_in_cluster[empty_clusters[i]] = 1

    for i in range(labels.shape[0]):
        curr_label = labels[i]
        for ind in range(indptr[i], indptr[i + 1]):
            j = indices[ind]
            centers[curr_label, j] += data[ind]

    centers /= n_samples_in_cluster[:, np.newaxis]

    return centers
