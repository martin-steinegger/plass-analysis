
from keras.models import Sequential
from keras.layers import Dense, Activation, Dropout, BatchNormalization
from keras import regularizers
from keras.regularizers import WeightRegularizer, l2 # import l2 regularizer
from keras.utils import np_utils # For y values
from keras.callbacks import ModelCheckpoint, EarlyStopping
from sklearn.cross_validation import StratifiedKFold
from sklearn.metrics import roc_auc_score
from sklearn.metrics import average_precision_score
from keras.models import load_model
from kerasify import export_model
import numpy as np

#pos = np.loadtxt('pos_labels', delimiter=' ', dtype=np.float32, usecols=range(91))
pos = np.loadtxt('pos_sprot_57_labels', delimiter=' ', dtype=np.float32, usecols=range(57))
neg = np.loadtxt('neg_57_labels', delimiter=' ', dtype=np.float32, usecols=range(57))
neg = np.resize(neg, (len(pos),57))

y = np.array([1] * len(pos) + [0] * len(neg))
X = np.concatenate((pos,neg), axis=0)

print 'Spliting train, valid, test parts...'
n_seqs = len(X)
indices = np.arange(n_seqs)
np.random.shuffle(indices)
X = X[indices]
y = y[indices]

n_tr = int(n_seqs * 0.85)
n_va = int(n_seqs * 0.05)
n_te = n_seqs - n_tr - n_va
X_train = X[:n_tr]
y_train = y[:n_tr]
X_valid = X[n_tr:n_tr+n_va]
y_valid = y[n_tr:n_tr+n_va]
X_test = X[-n_te:]
y_test = y[-n_te:]

def create_model():
    model = Sequential()
    model.add(Dense(units=32, input_dim=pos.shape[1], activation='relu'))
	model.add(Dropout(0.1))
    model.add(Dense(units=64, activation="relu"))
	model.add(Dropout(0.1))
    model.add(Dense(units=1, activation='sigmoid'))
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    return model 

model = None # Clearing the NN.
model = create_model()

checkpointer = ModelCheckpoint(filepath="sprot_training_57_dropout_32_64_1.hdf5", verbose=1, save_best_only=True)
earlystopper = EarlyStopping(monitor='val_loss', patience=10, verbose=1)

model.fit(X_train, y_train, epochs=1000, batch_size=32000, callbacks=[checkpointer], validation_data=(X_valid, y_valid), verbose=1, shuffle = True)

model = load_model("sprot_training_57_dropout_32_64_1.hdf5")

# eval
tresults = model.evaluate(X_test, y_test)
print tresults
y_pred = model.predict(X_test, batch_size=8192, verbose=1)
y = y_test
print 'Calculating AUC...'
auroc = roc_auc_score(y, y_pred)
auprc = average_precision_score(y, y_pred)
print auroc, auprc

export_model(model, 'sprot_training_57_dropout_32_64_1.kerasify')
