import numpy as np
from .decision_tree_regressor import DecisionTreeRegressor

class RandomForestRegressor:
    def __init__(
        self,
        n_estimators=200,
        max_depth=8,
        min_samples_split=10,
        min_samples_leaf=5,
        max_features=0.7,
        bootstrap_sample_size=None,
        random_state=None
    ):
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.min_samples_leaf = min_samples_leaf
        self.max_features = max_features
        self.bootstrap_sample_size = bootstrap_sample_size

        self.rng = np.random.default_rng(random_state)
        self.trees = []

    def _create_bootstrap_samples(self, x, y):
        bootstrap_samples_x = []
        bootstrap_samples_y = []

        sample_size = self.bootstrap_sample_size

        if sample_size is None:
            sample_size = x.shape[0]

        for i in range(self.n_estimators):
            sampled_idx = self.rng.choice(
                x.shape[0],
                size=sample_size,
                replace=True
            )

            bootstrap_samples_x.append(x[sampled_idx])
            bootstrap_samples_y.append(y[sampled_idx])

        return bootstrap_samples_x, bootstrap_samples_y

    def _create_base_learner(self):
        return DecisionTreeRegressor(
            max_depth=self.max_depth,
            min_samples_split=self.min_samples_split,
            min_samples_leaf=self.min_samples_leaf,
            max_features=self.max_features,
            random_state=self.rng.integers(0, 2**32)
        )

    def fit(self, x, y):
        x = np.asarray(x)
        y = np.asarray(y)

        if len(x) == 0 or len(y) == 0:
            raise ValueError("Training data cannot be empty.")

        if len(x) != len(y):
            raise ValueError("X and y must contain the same number of samples.")

        if self.n_estimators <= 0:
            raise ValueError("n_estimators must be greater than zero.")

        self.trees = []

        bootstrap_samples_x, bootstrap_samples_y = (
            self._create_bootstrap_samples(x, y)
        )

        for i in range(self.n_estimators):
            tree = self._create_base_learner()

            tree.fit(
                bootstrap_samples_x[i],
                bootstrap_samples_y[i]
            )

            self.trees.append(tree)

        return self

    def predict(self, x):
        if not self.trees:
            raise ValueError("Model has not been trained. Call fit() first.")

        x = np.asarray(x)

        predictions = np.array([
            tree.predict(x)
            for tree in self.trees
        ])

        return np.mean(predictions, axis=0)
