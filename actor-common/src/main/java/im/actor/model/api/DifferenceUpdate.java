package im.actor.model.api;
/*
 *  Generated by the Actor API Scheme generator.  DO NOT EDIT!
 */

import im.actor.model.droidkit.bser.Bser;
import im.actor.model.droidkit.bser.BserObject;
import im.actor.model.droidkit.bser.BserValues;
import im.actor.model.droidkit.bser.BserWriter;
import static im.actor.model.droidkit.bser.Utils.*;
import java.io.IOException;
import im.actor.model.network.parser.*;
import java.util.List;
import java.util.ArrayList;

public class DifferenceUpdate extends BserObject {

    private int updateHeader;
    private byte[] update;

    public DifferenceUpdate(int updateHeader, byte[] update) {
        this.updateHeader = updateHeader;
        this.update = update;
    }

    public DifferenceUpdate() {

    }

    public int getUpdateHeader() {
        return this.updateHeader;
    }

    public byte[] getUpdate() {
        return this.update;
    }

    @Override
    public void parse(BserValues values) throws IOException {
        this.updateHeader = values.getInt(1);
        this.update = values.getBytes(2);
    }

    @Override
    public void serialize(BserWriter writer) throws IOException {
        writer.writeInt(1, this.updateHeader);
        if (this.update == null) {
            throw new IOException();
        }
        writer.writeBytes(2, this.update);
    }

    @Override
    public String toString() {
        String res = "struct DifferenceUpdate{";
        res += "updateHeader=" + this.updateHeader;
        res += ", update=" + byteArrayToStringCompact(this.update);
        res += "}";
        return res;
    }

}
