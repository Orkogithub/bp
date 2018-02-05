import env
from aplos.interfaces import AplosInterfaces
from aplos.lib.abac.category import CategoryKey
from aplos.lib.marketplace_item.marketplace_item_consts import ENABLE
import util.zookeeper.zookeeper_interface as zookeeper_interface
from aplos.lib.db.zkpaths import ZkPaths

interfaces = AplosInterfaces()
zks = interfaces.zk_session


def is_calm_enabled():
  """
  Return True if Calm is already enabled
  """
  # Check for the zk node.
  print "Checking if Calm is enabled"
  zk_node = zookeeper_interface.ZkNode(
    zks,
    zk_path=ZkPaths.ENABLE_NUTANIX_APPS
  )
  is_calm = (zk_node.get() == ENABLE)
  return is_calm


def maybe_mark_AppFamily_internal():
  """
  If Calm is enabled and Appfamily is marked internal due to ENG-123716,
  mark it external again
  """
  category_key = CategoryKey(name='AppFamily')
  print "Checking if AppFamily is internal and calm is enabled."
  if category_key.exists and category_key.internal\
     and is_calm_enabled():
    print "Marking AppFamily as external as Calm is enabled"
    category_key.internal = False
    category_key.save()
  else:
    print "Either Calm is not enabled or Category is not marked internal."
    print "Nothing to Do!"


maybe_mark_AppFamily_internal()
