/*
 * Copyright LWJGL. All rights reserved.
 * License terms: https://www.lwjgl.org/license
 */
package org.lwjgl.glfw;

import org.lwjgl.system.*;

import javax.annotation.*;

public abstract class GLFWIMEStatusCallback extends Callback implements GLFWIMEStatusCallbackI {

    protected GLFWIMEStatusCallback() {
        super(null);
    }

    @Nullable
    public static GLFWIMEStatusCallback create(GLFWIMEStatusCallbackI sam) {
        return null;
    }

    @Nullable
    public static GLFWIMEStatusCallback createSafe(long functionPointer) {
        return null;
    }

    @Override
    public void invoke(long window, boolean focused) {}
}
