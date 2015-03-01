package im.actor.model.api.rpc;
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
import im.actor.model.api.*;

public class ResponseGetPublicKeys extends Response {

    public static final int HEADER = 0x18;
    public static ResponseGetPublicKeys fromBytes(byte[] data) throws IOException {
        return Bser.parse(new ResponseGetPublicKeys(), data);
    }

    private List<PublicKey> keys;

    public ResponseGetPublicKeys(List<PublicKey> keys) {
        this.keys = keys;
    }

    public ResponseGetPublicKeys() {

    }

    public List<PublicKey> getKeys() {
        return this.keys;
    }

    @Override
    public void parse(BserValues values) throws IOException {
        List<PublicKey> _keys = new ArrayList<PublicKey>();
        for (int i = 0; i < values.getRepeatedCount(1); i ++) {
            _keys.add(new PublicKey());
        }
        this.keys = values.getRepeatedObj(1, _keys);
    }

    @Override
    public void serialize(BserWriter writer) throws IOException {
        writer.writeRepeatedObj(1, this.keys);
    }

    @Override
    public String toString() {
        String res = "tuple GetPublicKeys{";
        res += "}";
        return res;
    }

    @Override
    public int getHeaderKey() {
        return HEADER;
    }
}
