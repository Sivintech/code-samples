package com.sivintech.demo;

import java.util.LinkedList;
import java.util.List;

/**
 * FxFuture implementation which can be controlled externally
 */
public class FxFutureBasicImpl<T> implements FxFuture<T> {
    private boolean resultSet = false;
    private T result = null;
    private Throwable error = null;

    private List<CompletionCallback<T>> completionCallbacks = new LinkedList<>();
    private List<FailureCallback> failureCallbacks = new LinkedList<>();

    public BasicFxFutureImpl() {
    }

    public BasicFxFutureImpl(T value) {
        result = value;
        resultSet = true;
    }

    @Override
    public FxFuture<T> completion(CompletionCallback<T> callback) {
        if (resultSet) {
            if (error == null) {
                callback.call(result);
            }
        } else {
            completionCallbacks.add(callback);
        }
        return this;
    }

    @Override
    public FxFuture<T> failure(FailureCallback callback) {
        if (resultSet) {
            if (error != null) {
                callback.call(error);
            }
        } else {
            failureCallbacks.add(callback);
        }
        return this;
    }

    @Override
    public void cancel() {
        // ignore
    }

    public void complete(T result) {
        if (this.resultSet) {
            throw new IllegalStateException("BasicFxFutureImpl can be complete or failed only once");
        }
        this.resultSet = true;
        this.result = result;
        this.error = null;

        List<CompletionCallback<T>> completions = completionCallbacks;
        completionCallbacks = null;
        failureCallbacks = null;

        for (CompletionCallback<T> callback : completions) {
            callback.call(result);
        }
    }

    public void fail(Throwable error) {
        if (resultSet) {
            throw new IllegalStateException("BasicFxFutureImpl can be complete or failed only once");
        }
        this.resultSet = true;
        this.result = null;
        this.error = error;

        List<FailureCallback> failures = failureCallbacks;
        failureCallbacks = null;
        completionCallbacks = null;

        for (FailureCallback callback : failures) {
            callback.call(error);
        }
    }
}
