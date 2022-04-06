// eslint-disable-next-line @typescript-eslint/no-unused-vars
module.exports = function(doc, oldDoc) {
  if (doc.replRole) {
    requireRole('replicator');
    if (doc.replRole !== 'replicator') {
      requireRole(doc.replRole);
      channel(doc.replRole);
      if (doc.channels && doc.channels.length) {
        doc.channels.each(function(channel) {
          channel(doc.replRole + '_' + channel);
        });
      }
    }
  } else {
    requireRole('sync_daemon');
    channel(doc.channels);
  }
};
