#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import os, sys
import json
import collections

# using uppercase to avoid python namespace issues
nt_item_id = collections.namedtuple('nt_item_id', 'Name Class Referent')

class RojoConfig(object):
    def __init__(self, fname):
        self.cfg = json.load(open(fname))
        self.folder = os.path.dirname(fname)
        self.items = {} # key=nt_item_id, val=path

        self.tree = self.cfg.get('tree')
        if not self.tree:
            raise Exception('missing tree')
        for k, v in self.tree.items():
            self._parse_cfg(k, v, [])

        #for k, v in self.items.items():
        #    print('   ', k, v)

    def _parse_cfg(self, name, value, parents):
        if not isinstance(value, dict):
            return
        #print('_parse_cfg:', name, value)
        #print('          :', parents)
        iclass = value.get('$className')
        ipath  = value.get('$path')
        if ipath:
            self.items[nt_item_id(name, iclass, None)] = ipath
        for k, v in value.items():
            self._parse_cfg(k, v, parents + [name])

    def lookup_path(self, item_path):
        '''
        Match the item_path to a folder.
        The first level should always be Workspace/Workspace.
        Config:
            {
                "tree": {
                    key=Name
        '''
        ii = item_path[-1]
        if ii.Class == 'LocalScript':
            ext = '.client.lua'
        elif ii.Class == 'Script':
            ext = '.server.lua'
        else:
            ext = '.lua'
        fname = ii.Name + ext

        #print("\n", item_path)
        ext_path = []
        for ip in reversed(item_path[:-1]):
            #print(" lookfor:", ip)
            for k, v in self.items.items():
                if k.Name == ip.Name and k.Class == ip.Class:
                    #print(' ++ matched:', k, v, 'with ext:', list(reversed(ext_path)), fname)
                    ffn = v + '/' + '/'.join(reversed(ext_path)) + '/' + fname
                    #print('ffn:', ffn)
                    return ffn
            ext_path.append(ip.Name)

        print("WARNING: Do not know what to do with", item_path)
        sys.exit()
        return None


def find_tag(ch_list, tag_name):
    ''' Find the first child with tag=@tag_name '''
    for xx in ch_list:
        if xx.tag == tag_name:
            return xx
    return None

def get_text(node):
    if node.text:
        return node.text.strip()
    return ''

def process_value(prop_value):
    values = {}
    for ch in list(prop_value):
        values[ch.tag] = get_text(ch)
    if not values:
        if prop_value.text:
            values = get_text(prop_value)
        else:
            values = None
    elif len(values) == 1 and list(values)[0] == 'null':
        values = None

    return values

def process_properties(item):
    ''' process the Properties tag
    It consists only of elements of the following format:
        <type name="$(KEY)">$(VALUE)</type>

    Big assumption that KEY does not repeat.
    '''
    # 'Properties' appears to always be first, but lets make sure
    Properties = find_tag(item, 'Properties')
    if not Properties:
        return
    props = {}
    for ch in list(Properties):
        key = ch.get('name')
        vtype = ch.tag
        val = process_value(ch)
        props[key] = (vtype, val)
    return props

def resolve_script_fname(fname):
    ''' resolves a script filename
    Chop off the extension and check for a folder with that name.
    If found, then we instead store the script as 'init'.
    '''
    tmp = None
    dname = None
    for tmp in ('.server.lua', '.client.lua', '.lua'):
        if fname.endswith(tmp):
            ext = tmp
            dname = fname[:-len(tmp)]
            break

    if dname:
        if os.path.isdir(dname):
            return os.path.join(dname, 'init' + ext)
    return fname

def save_file_if_changed(fname, text):
    fname = resolve_script_fname(fname)

    # filter the text trimming trailing space and newlines
    new_text_lines = []
    for line in text.splitlines():
        new_text_lines.append(line.rstrip())
    while len(new_text_lines) > 1 and not new_text_lines[-1]:
        del new_text_lines[-1]
    new_text_lines.append('')
    new_text = '\n'.join(new_text_lines)

    try:
        old_text = str(open(fname, 'rb').read(), 'utf-8')
    except Exception as e:
        print(e)
        old_text = ''
    if old_text != new_text:
        #print('=== old_text ===')
        #print(old_text)
        #print('=== new_text ===')
        #print(new_text)
        #print('=== end ===')

        dname = os.path.dirname(fname)
        if not os.path.exists(dname):
            os.makedirs(dname)
        with open(fname, 'wb') as fh:
            fh.write(bytes(new_text, 'utf-8'))
        print("Wrote:", fname)
    else:
        print("Unchanged:", fname)

def save_source(cfg, item_path, text):
    fname = cfg.lookup_path(item_path)
    if fname:
        save_file_if_changed(fname, text)

def print_item(cfg, item, parents):
    iclass = item.get('class')
    if not iclass:
        print("ERROR: no_class", item)
        return
    ch = list(item)
    if not ch:
        print("ERROR: no children", item)
        return

    pi = process_properties(item)

    iname = pi.get('Name')[1]
    if not iname:
        print("ERROR: no Name in properties", item)
        return

    # The item looks good
    item_id = nt_item_id(iname, iclass, item.get('referent'))

    item_path = parents + [item_id]
    #print(' ', item_path)
    #for k, v in pi.items():
    #    print('  - ', k, v)

    if iclass in ('Script', 'ModuleScript', 'LocalScript'):
        #print('\n\n-->',)
        #ind = ''
        #for ip in item_path:
        #    print(ind, ip,)
        #    ind += '  '
        #print()

        text = pi.get('Source')[1]
        #print('--- begin source ---')
        #print(text)
        #print('--- end source ---')
        save_source(cfg, item_path, text)

    # call on all children that are tagged with 'Item'
    for xx in ch:
        if xx.tag == 'Item':
            print_item(cfg, xx, item_path)


def main(argv):
    if len(argv) != 2:
        return 'Usage: %s CONFIG_JSON RBXLX_FNAME' % (os.path.basename(sys.argv[0]),)
    cfg_fname = argv[0]
    xml_fname = argv[1]

    jcfg = RojoConfig(cfg_fname)
    #print('Config:', json.dumps(jcfg.cfg, indent=2))

    tree = ET.parse(xml_fname)
    root = tree.getroot()

    # OK, scan looking for scripts.
    for ch in list(root):
        if ch.tag == 'Item':
            print_item(jcfg, ch, [])

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
