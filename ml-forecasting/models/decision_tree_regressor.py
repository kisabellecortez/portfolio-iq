import numpy as np

class DecisionTreeRegressor:
    def __init__(
        self,
        max_depth=8,
        min_samples_split=10,
        min_samples_leaf=5,
        max_features=None,
        random_state=None
    ) -> None:
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.min_samples_leaf = min_samples_leaf
        self.max_features = max_features
        self.rng = np.random.default_rng(random_state)

        self.root = None

    def _calculate_mse(self, y):
        return np.mean((y - np.mean(y)) ** 2)

    def _split_data(self, x, y, feature_idx, threshold):
        left_x = []
        left_y = []

        right_x = []
        right_y = []

        for i in range(len(x)):
            if x[i][feature_idx] >= threshold:
                right_x.append(x[i])
                right_y.append(y[i])
            else:
                left_x.append(x[i])
                left_y.append(y[i])

        return (
            np.array(left_x),
            np.array(left_y),
            np.array(right_x),
            np.array(right_y)
        )

    def _find_best_split(self, x, y):
        best_feature_idx = None
        best_threshold = None
        best_mse = float("inf")

        n_samples, n_features = x.shape

        if self.max_features is None:
            feature_indices = np.arange(n_features)

        else:
            if isinstance(self.max_features, float):
                n_selected = max(1, int(self.max_features * n_features))
            else:
                n_selected = min(self.max_features, n_features)

            feature_indices = self.rng.choice(
                n_features,
                size=n_selected,
                replace=False
            )

        for feature_idx in feature_indices:
            values = np.unique(x[:, feature_idx])

            thresholds = (
                values[:-1] + values[1:]
            ) / 2

            for threshold in thresholds:
                left_x, left_y, right_x, right_y = self._split_data(
                    x, y, feature_idx, threshold
                )

                if (
                    len(left_y) < self.min_samples_leaf
                    or len(right_y) < self.min_samples_leaf
                ):
                    continue

                weighted_mse = (
                    len(left_y) / n_samples * self._calculate_mse(left_y)
                    + len(right_y) / n_samples * self._calculate_mse(right_y)
                )

                if weighted_mse < best_mse:
                    best_feature_idx = feature_idx
                    best_threshold = threshold
                    best_mse = weighted_mse

        return best_feature_idx, best_threshold, best_mse

    def _build_tree(self, x, y, depth=0):
        if (
            depth >= self.max_depth
            or len(y) < self.min_samples_split
            or np.all(y == y[0])
        ):
            return self._create_leaf(y)

        feature_idx, threshold, best_mse = self._find_best_split(x, y)

        if feature_idx is None:
            return self._create_leaf(y)

        left_x, left_y, right_x, right_y = self._split_data(
            x, y, feature_idx, threshold
        )

        left_child = self._build_tree(left_x, left_y, depth + 1)
        right_child = self._build_tree(right_x, right_y, depth + 1)

        return {
            "feature_idx": feature_idx,
            "threshold": threshold,
            "left": left_child,
            "right": right_child
        }

    def _create_leaf(self, y):
        return {"value": np.mean(y)}

    def _predict_sample(self, sample, node):
        if "value" in node:
            return node["value"]

        feature_value = sample[node["feature_idx"]]

        if feature_value < node["threshold"]:
            return self._predict_sample(sample, node["left"])

        return self._predict_sample(sample, node["right"])

    def fit(self, x, y):
        x = np.asarray(x)
        y = np.asarray(y)

        if len(x) == 0 or len(y) == 0:
            raise ValueError("Training data cannot be empty.")

        if len(x) != len(y):
            raise ValueError("X and y must contain the same number of samples.")

        self.root = self._build_tree(x, y, depth=0)

        return self

    def predict(self, x):
        if self.root is None:
            raise ValueError("Model has not been trained. Call fit() first.")

        x = np.asarray(x)

        predictions = []

        for sample in x:
            prediction = self._predict_sample(sample, self.root)
            predictions.append(prediction)

        return np.array(predictions)
